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

    func syncInventory(forUser: User, modelContext: ModelContext) async throws {
        print("## Sync inventory for user \(forUser.username)")
        // Sync when never synced (lastInventorySync == nil) or when new items
        // were added on the server since the last sync.
        if let lastSync = forUser.lastInventorySync, forUser.lastItemAdded <= lastSync {
            print("     -> no need to refresh")
            return
        }
        print("     -> syncing... ")

        let result: InventoryResultDTO? = try await apiService.fetchData(fromEndpoint: "/api/items/inventory-view?user=\(forUser._id)")
        guard let result else { return }

        // Sync authors and works
        for authorUri: String in result.worksTree.author.keys {
            guard let authorWorkUris: [String] = result.worksTree.author[authorUri] else { continue }
            guard let workDTOs = try? await entityModel?.fetchEntities(modelContext: modelContext, uris: authorWorkUris) else { continue }

            if authorUri == InventoryModel.unkownAuthorId {
                for work in workDTOs {
                    modelContext.insert(Work(entityDTO: work, authors: [], apiService: apiService))
                }
            } else {
                guard let authors: [Author] = try await entityModel?.getOrFetchAuthors(modelContext: modelContext, uris: [authorUri]) else { continue }
                for work in workDTOs {
                    for author in authors {
                        author.works.append(Work(entityDTO: work, authors: authors, apiService: apiService))
                        modelContext.insert(author)
                    }
                }
            }
        }

        // Sync items and their editions
        for workUri in result.workUriItemsMap.keys {
            guard let relatedWork = try? entityModel?.getLocalWork(modelContext: modelContext, uri: workUri) else { continue }

            guard let ids: String = result.workUriItemsMap[workUri]?.joined(separator: "|") else { continue }
            let itemsUrl: String = "/api/items/by-ids?ids=\(ids)"

            guard let itemsDTO: ItemsDTO = try await apiService.fetchData(fromEndpoint: itemsUrl) else { continue }

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
                    if myItem.edition?.works.filter({ $0.uri == relatedWork.uri }).count == 0 {
                        myItem.edition?.works.append(relatedWork)
                    }
                } else {
                    let myItem: InventoryItem = .init(itemDTO: itemDTO, forUser: forUser, apiService: apiService)
                    myItem.shelves = shelves
                    myItem.edition?.works.append(relatedWork)
                    modelContext.insert(myItem)
                }
            }
        }

        forUser.lastInventorySync = Date().timeIntervalSince1970 * 1000 // milliseconds
        try modelContext.save()
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

        let newItem: InventoryItem = .init(itemDTO: response.item, forUser: forUser, apiService: apiService)
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
            revert: { item.details = previous },
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
