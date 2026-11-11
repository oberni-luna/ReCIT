//
//  InventoryModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftData
import Foundation
import AsyncAlgorithms
import OSLog

@MainActor
@Observable
final class InventoryModel: OptimisticMutating {
    private static let signposter: OSSignposter = .init(subsystem: "asso.recits", category: "sync")
    private static let logger: Logger = .init(subsystem: "asso.recits", category: "inventory")
    private let apiService: APIServicing

    /// Shared channel used to surface a background optimistic failure to the UI.
    var errorReporter: AppErrorReporter?

    /// Progress of the first syncs running right now, by user id. Only first syncs: a later
    /// refresh lands on books already on screen and has nothing to announce. Never persisted —
    /// a sync cut short by a relaunch starts over, and so does its bar.
    private(set) var firstSyncProgress: [String: InventorySyncProgress] = [:]

    /// Most recent optimistic background task, exposed so tests can await it.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?
    /// The last write of each book's text, which the next write of that text waits for.
    @ObservationIgnored private var lastTextWrites: [TextWrite: Task<Void, Never>] = [:]

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
    }

    // MARK: - Sync

    /// What a screen shows of `user`'s inventory while it has never been synced.
    func firstSyncState(for user: User) -> InventoryFirstSyncState {
        .init(lastInventorySync: user.lastInventorySync, progress: firstSyncProgress[user._id])
    }

    /// Syncs `forUser`'s inventory when it has never been synced, or when inventaire.io has
    /// books added since. The work runs in an `InventorySync`, off the main actor, which writes
    /// its own context of `modelContext`'s container — never `modelContext` (ADR 0009).
    func syncInventory(forUser: User, modelContext: ModelContext) async throws {
        let isFirstSync: Bool = forUser.lastInventorySync == nil
        var announcedItemCount: Int = 0
        let signpostState: OSSignpostIntervalState = Self.signposter.beginInterval("Inventory sync", id: Self.signposter.makeSignpostID())
        defer {
            Self.signposter.endInterval("Inventory sync", signpostState, "firstSync: \(isFirstSync, privacy: .public), items: \(announcedItemCount, privacy: .public)")
        }
        if let lastSync = forUser.lastInventorySync, forUser.lastItemAdded <= lastSync {
            Self.logger.debug("Inventory of \(forUser.username, privacy: .private) already up to date")
            return
        }

        let userId: String = forUser._id
        if isFirstSync {
            firstSyncProgress[userId] = .init()
        }
        // Cleared however the sync ends: on success `lastInventorySync` has taken over, on
        // failure the user goes back to waiting for the next refresh.
        defer { firstSyncProgress[userId] = nil }

        let sync: InventorySync = .init(modelContainer: modelContext.container, apiService: apiService)
        let (updates, progress): (AsyncStream<InventorySyncProgress>, AsyncStream<InventorySyncProgress>.Continuation) = AsyncStream.makeStream()
        async let announced: Int = sync.sync(userID: userId, progress: progress)
        for await update in updates where isFirstSync {
            firstSyncProgress[userId] = update
        }
        announcedItemCount = try await announced

        // The main context does not take a background save into the models it already holds: a
        // fetch does. `forUser` is one of them, and its first sync state reads it.
        _ = try? modelContext.fetch(FetchDescriptor<User>(predicate: #Predicate { $0._id == userId }))
    }

    // MARK: - Item management

    func postNewItem(
        modelContext: ModelContext,
        entityUri: String,
        transaction: TransactionType,
        visibility: [VisibilityAttributes],
        forUser: User
    ) async throws -> InventoryItem {
        let payload: NewItemDTO = .init(
            entity: entityUri,
            details: nil,
            notes: nil,
            transaction: transaction.rawValue,
            visibility: visibility.map { $0.rawValue },
            shelves: []
        )

        guard let response: PostItemResponseDTO = try await apiService.send(toEndpoint: "/api/items", payload: payload, debug: true) else {
            throw NetworkError.badResponse
        }

        let edition: Edition = try modelContext.edition(uri: response.item.entity, snapshot: response.item.snapshot, apiService: apiService)
        let newItem: InventoryItem = .init(itemDTO: response.item, forUser: forUser, edition: edition)
        modelContext.insert(newItem)
        try modelContext.save()
        return newItem
    }

    func removeItem(_ item: InventoryItem, modelContext: ModelContext) async throws {
        let payload: [String: [String]] = ["ids": [item._id]]

        guard let ok: [String: Bool] = try await apiService.send(toEndpoint: "/api/items/delete", payload: payload) else {
            throw NetworkError.badResponse
        }

        if let ok: Bool = ok["ok"], ok == true {
            modelContext.delete(item)
            try modelContext.save()
        }
    }

    func getOrFetchItem(modelContext: ModelContext, itemId: String) throws -> InventoryItem? {
        try getLocalItem(modelContext: modelContext, id: itemId)
    }

    // MARK: - Item updates

    /// Optimistically sets the item's transaction mode: persists locally at once,
    /// pushes to the server in the background, and reverts to `previous` on failure.
    func updateItemTransactionOptimistic(
        item: InventoryItem,
        newValue: TransactionType,
        previous: TransactionType,
        modelContext: ModelContext
    ) {
        inFlightTask = optimistic(
            modelContext,
            subjects: [item],
            apply: { item.transaction = newValue },
            revert: { item.transaction = previous },
            request: { [weak self] in
                let response: UpdateItemsResponseDTO? = try await self?.updateItems(ids: [item._id], attribute: "transaction", value: newValue.rawValue)
                guard response?.ok == true else { throw NetworkError.badResponse }
            }
        )
    }

    /// Optimistically sets one of the item's texts: persists locally at once,
    /// pushes to the server in the background, and reverts on failure.
    func updateItemTextOptimistic(
        item: InventoryItem,
        attribute: InventoryItemTextAttribute,
        text: String,
        modelContext: ModelContext
    ) {
        let keyPath: ReferenceWritableKeyPath<InventoryItem, String> = attribute.keyPath
        let previous: String = item[keyPath: keyPath]
        let write: TextWrite = .init(itemID: item._id, attribute: attribute)
        let earlierWrite: Task<Void, Never>? = lastTextWrites[write]
        let task: Task<Void, Never> = optimistic(
            modelContext,
            subjects: [item],
            apply: { item[keyPath: keyPath] = text },
            revert: {
                // Autosave can queue several writes; a stale failure must not clobber a newer note.
                if item[keyPath: keyPath] == text {
                    item[keyPath: keyPath] = previous
                }
            },
            request: { [weak self] in
                await earlierWrite?.value
                let response: UpdateItemsResponseDTO? = try await self?.updateItems(ids: [item._id], attribute: attribute.rawValue, value: text)
                guard response?.ok == true else { throw NetworkError.badResponse }
            }
        )
        lastTextWrites[write] = task
        inFlightTask = task
    }

    func updateItems(ids: [String], attribute: String, value: String?) async throws -> UpdateItemsResponseDTO? {
        try await apiService.send(
            toEndpoint: "/api/items/bulk-update",
            method: "PUT",
            payload: UpdateItemsDTO(
                ids: ids,
                attribute: attribute,
                value: value ?? ""
            ),
            debug: true
        )
    }

    // MARK: - Private helpers

    private func getLocalItem(modelContext: ModelContext, id: String) throws -> InventoryItem? {
        let predicate: Predicate<InventoryItem> = #Predicate { object in
            object._id == id
        }
        let descriptor: FetchDescriptor<InventoryItem> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
}

private extension InventoryModel {
    struct TextWrite: Hashable {
        let itemID: String
        let attribute: InventoryItemTextAttribute
    }
}
