//
//  InventoryModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftData
import Foundation
import AsyncAlgorithms

@MainActor
@Observable
final class InventoryModel: OptimisticMutating {
    private static let unkownAuthorId: String = "unknown"
    private let apiService: APIServicing
    private var entityModel: EntityModel?

    /// Shared channel used to surface a background optimistic failure to the UI.
    var errorReporter: AppErrorReporter?

    /// Most recent optimistic background task, exposed so tests can await it.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
    }

    func start(entityModel: EntityModel, errorReporter: AppErrorReporter) {
        self.entityModel = entityModel
        self.errorReporter = errorReporter
    }

    // MARK: - Sync

    /// Progress of the first syncs running right now, by user id. Only first syncs: a later
    /// refresh lands on books already on screen and has nothing to announce. Never persisted —
    /// a sync cut short by a relaunch starts over, and so does its bar.
    private(set) var firstSyncProgress: [String: InventorySyncProgress] = [:]

    /// What a screen shows of `user`'s inventory while it has never been synced.
    func firstSyncState(for user: User) -> InventoryFirstSyncState {
        .init(lastInventorySync: user.lastInventorySync, progress: firstSyncProgress[user._id])
    }

    func syncInventory(forUser: User, modelContext: ModelContext) async throws {
        print("## Sync inventory for user \(forUser.username)")
        // Sync when never synced (lastInventorySync == nil) or when new items
        // were added on the server since the last sync.
        if let lastSync = forUser.lastInventorySync, forUser.lastItemAdded <= lastSync {
            print("     -> no need to refresh")
            return
        }
        print("     -> syncing... ")

        let userId: String = forUser._id
        let isFirstSync: Bool = forUser.lastInventorySync == nil
        if isFirstSync {
            firstSyncProgress[userId] = .init()
        }
        // Cleared however the sync ends: on success `lastInventorySync` has taken over, on
        // failure the user goes back to waiting for the next refresh.
        defer { firstSyncProgress[userId] = nil }

        let result: InventoryResultDTO? = try await apiService.fetchData(fromEndpoint: "/api/items/inventory-view?user=\(forUser._id)")
        guard let result else { return }

        if isFirstSync {
            firstSyncProgress[userId] = .init(workUriItemsMap: result.workUriItemsMap)
        }

        // Each author's works, then at once the items of those works — rather than every work
        // first and every item after, which kept a first sync's bar at zero for as long as the
        // works took and then ran it to the end in one go.
        var syncedWorkUris: Set<String> = []
        for authorUri: String in result.worksTree.author.keys {
            guard let authorWorkUris: [String] = result.worksTree.author[authorUri] else { continue }
            guard let workDTOs = try? await entityModel?.fetchEntities(modelContext: modelContext, uris: authorWorkUris) else { continue }

            // Upserted, never built: a `Work` made afresh here on every sync used to empty the
            // stored one's genres and preferred edition, and leave a row-less twin behind for
            // whoever held it (issue 0067). A work under two authors arrives under each, and
            // keeps both.
            let authors: [Author]
            if authorUri == InventoryModel.unkownAuthorId {
                authors = []
            } else {
                // `try?` like the works above: one author the server answers badly must not
                // stop the whole inventory — its works fall to the loop after this one.
                guard let fetched: [Author] = try? await entityModel?.getOrFetchAuthors(modelContext: modelContext, uris: [authorUri]) else { continue }
                authors = fetched
            }
            for work in workDTOs {
                try modelContext.upsertWork(work, authors: authors, apiService: apiService)
            }

            for workUri in authorWorkUris where !syncedWorkUris.contains(workUri) {
                try await syncItems(ofWork: workUri, in: result, forUser: forUser, modelContext: modelContext)
                syncedWorkUris.insert(workUri)
            }
            // Saved per author, so a first sync's books reach the screen as they arrive
            // instead of all together at the end.
            try modelContext.save()
        }

        // The works no author claimed, or whose author could not be fetched: their items
        // were synced before this loop was split, and still are.
        for workUri in result.workUriItemsMap.keys where !syncedWorkUris.contains(workUri) {
            try await syncItems(ofWork: workUri, in: result, forUser: forUser, modelContext: modelContext)
        }

        forUser.lastInventorySync = Date().timeIntervalSince1970 * 1000 // milliseconds
        try modelContext.save()
    }

    /// Upserts the items `result` files under `workUri`, and counts them into the first sync's
    /// progress — counted even when the work or its items cannot be had, so the bar still
    /// reaches its end on an inventory that has holes.
    private func syncItems(
        ofWork workUri: String,
        in result: InventoryResultDTO,
        forUser: User,
        modelContext: ModelContext
    ) async throws {
        guard let itemIds: [String] = result.workUriItemsMap[workUri] else { return }
        defer { firstSyncProgress[forUser._id]?.receive(itemIds) }

        guard let relatedWork = try? entityModel?.getLocalWork(modelContext: modelContext, uri: workUri) else { return }

        let itemsUrl: String = "/api/items/by-ids?ids=\(itemIds.joined(separator: "|"))"
        guard let itemsDTO: ItemsDTO = try await apiService.fetchData(fromEndpoint: itemsUrl) else { return }

        for itemDTO in itemsDTO.items {
            // Resolve shelf membership into the many-to-many relation. Shelves are
            // synced before inventory, so the local `Shelf` objects already exist.
            // Skipped while an optimistic membership write is unconfirmed: this
            // assignment is wholesale and would undo it on screen (PRD 0004).
            let assignsShelves: Bool = ShelfModel.isMembershipWriteInFlight == false
            let shelves: [Shelf] = getLocalShelves(modelContext: modelContext, ids: itemDTO.shelves ?? [])
            if let myItem = try? getLocalItem(modelContext: modelContext, id: itemDTO._id) {
                // Upsert in place — keep identity so open item views stay reactive.
                myItem.update(from: itemDTO, forUser: forUser, apiService: apiService)
                if assignsShelves { myItem.shelves = shelves }
                myItem.edition?.mergeWorks([relatedWork])
            } else {
                let edition: Edition = try modelContext.edition(uri: itemDTO.entity, snapshot: itemDTO.snapshot, apiService: apiService)
                let myItem: InventoryItem = .init(itemDTO: itemDTO, forUser: forUser, edition: edition)
                myItem.shelves = shelves
                edition.mergeWorks([relatedWork])
                modelContext.insert(myItem)
            }
        }
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
            apply: { item.transaction = newValue },
            revert: { item.transaction = previous },
            request: { [weak self] in
                let response: UpdateItemsResponseDTO? = try await self?.updateItems(ids: [item._id], attribute: "transaction", value: newValue.rawValue)
                guard response?.ok == true else { throw NetworkError.badResponse }
            }
        )
    }

    /// Optimistically sets the item's details/notes: persists locally at once,
    /// pushes to the server in the background, and reverts on failure.
    func updateItemDetailsOptimistic(
        item: InventoryItem,
        details: String,
        modelContext: ModelContext
    ) {
        let previous: String = item.details
        inFlightTask = optimistic(
            modelContext,
            apply: { item.details = details },
            revert: {
                // Autosave can queue several writes; a stale failure must not clobber a newer note.
                if item.details == details {
                    item.details = previous
                }
            },
            request: { [weak self] in
                let response: UpdateItemsResponseDTO? = try await self?.updateItems(ids: [item._id], attribute: "details", value: details)
                guard response?.ok == true else { throw NetworkError.badResponse }
            }
        )
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

    /// Resolves shelf ids (from an item's server `shelves` array) into local `Shelf`
    /// objects. Returns an empty array when the item is on no shelf ("sans étagère").
    private func getLocalShelves(modelContext: ModelContext, ids: [String]) -> [Shelf] {
        guard !ids.isEmpty else { return [] }
        let descriptor: FetchDescriptor<Shelf> = .init(
            predicate: #Predicate { shelf in ids.contains(shelf._id) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
