//
//  InventorySync.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/11/2026.
//

import Foundation
import OSLog
import SwiftData

/// A reader's inventory, fetched from inventaire.io and merged into the store off the main actor
/// (ADR 0009). `InventoryModel.syncInventory` makes one per sync and waits for it.
///
/// It writes its own context only, and saves it at most once every `saveInterval`, then once at
/// the end: each save is one refetch of the `@Query`s on screen, so the books still arrive as
/// they come without costing the scroll one refetch per author. Each save reports how far the
/// sync has got. An item with a write in flight (`InFlightWrites`) is left as it is: the server
/// has not seen that write yet, and merging its answer would undo it on screen.
///
/// A model actor runs each job on the thread that hands it over: called from the main actor, or
/// coming back from it, it would run there. So it is entered through a `@concurrent` method, and
/// never awaits the main actor — the progress leaves through an `AsyncStream`.
actor InventorySync: ModelActor {
    private static let unknownAuthorURI: String = "unknown"
    private static let logger: Logger = .init(subsystem: "asso.recits", category: "inventory")

    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    private let apiService: any APIServicing
    private let inFlightWrites: InFlightWrites
    private let saveInterval: Duration
    private let entitySync: EntitySync

    init(
        modelContainer: ModelContainer,
        apiService: any APIServicing,
        inFlightWrites: InFlightWrites = .shared,
        saveInterval: Duration = .seconds(1)
    ) {
        let modelExecutor: any ModelExecutor = DefaultSerialModelExecutor(modelContext: .init(modelContainer))
        self.modelContainer = modelContainer
        self.modelExecutor = modelExecutor
        self.apiService = apiService
        self.inFlightWrites = inFlightWrites
        self.saveInterval = saveInterval
        self.entitySync = .init(
            modelExecutor: modelExecutor,
            modelContainer: modelContainer,
            apiService: apiService
        )
    }

    /// Syncs the inventory of the user under `userID`, and answers how many items inventaire.io
    /// announced.
    ///
    /// - Parameter progress: Given the progress once the items are announced, then at each save,
    ///   and finished when the sync ends, however it ends. Items are counted even when their work
    ///   or they themselves cannot be had, so the bar still reaches its end on an inventory that
    ///   has holes.
    @concurrent
    nonisolated func sync(
        userID: String,
        progress: AsyncStream<InventorySyncProgress>.Continuation
    ) async throws -> Int {
        defer { progress.finish() }
        return try await run(userID: userID, progress: progress)
    }

    /// Each author's works, then at once the items of those works — rather than every work first
    /// and every item after, which kept a first sync's bar at zero for as long as the works took.
    private func run(
        userID: String,
        progress continuation: AsyncStream<InventorySyncProgress>.Continuation
    ) async throws -> Int {
        let owner: User? = try modelContext.fetch(FetchDescriptor<User>(predicate: #Predicate { $0._id == userID })).first
        guard let owner else {
            Self.logger.error("Inventory sync skipped: its owner is not in the store")
            return 0
        }
        let endpoint: String = "/api/items/inventory-view?user=\(userID)"
        guard let result: InventoryResultDTO = try await apiService.fetchData(fromEndpoint: endpoint) else { return 0 }

        var progress: InventorySyncProgress = .init(workUriItemsMap: result.workUriItemsMap)
        continuation.yield(progress)
        var lastSave: ContinuousClock.Instant = .now
        var syncedWorkURIs: Set<String> = []

        for (authorURI, workURIs) in result.worksTree.author {
            // One author the server answers badly must not stop the whole inventory: its works
            // fall to the loop after this one.
            do {
                try await entitySync.upsertWorks(
                    uris: workURIs,
                    authorURI: authorURI == Self.unknownAuthorURI ? nil : authorURI
                )
            } catch {
                Self.logger.error("Works of \(authorURI, privacy: .public) skipped: \(error)")
                continue
            }
            for workURI in workURIs where syncedWorkURIs.contains(workURI) == false {
                try await syncItems(ofWork: workURI, in: result, owner: owner)
                progress.receive(result.workUriItemsMap[workURI] ?? [])
                syncedWorkURIs.insert(workURI)
            }
            if lastSave.duration(to: .now) >= saveInterval {
                try save(progress, reportingTo: continuation)
                lastSave = .now
            }
        }

        // The works no author claimed, or whose author could not be fetched.
        for workURI in result.workUriItemsMap.keys where syncedWorkURIs.contains(workURI) == false {
            try await syncItems(ofWork: workURI, in: result, owner: owner)
            progress.receive(result.workUriItemsMap[workURI] ?? [])
        }

        owner.lastInventorySync = Date().timeIntervalSince1970 * 1000 // milliseconds
        try save(progress, reportingTo: continuation)
        return progress.total ?? 0
    }

    /// Merges the items `result` files under `workURI` into the store.
    private func syncItems(
        ofWork workURI: String,
        in result: InventoryResultDTO,
        owner: User
    ) async throws {
        guard
            let itemIDs = result.workUriItemsMap[workURI],
            let work = try? modelContext.fetch(FetchDescriptor<Work>(predicate: #Predicate { $0.uri == workURI })).first
        else {
            return
        }

        let endpoint: String = "/api/items/by-ids?ids=\(itemIDs.joined(separator: "|"))"
        guard let answer: ItemsDTO = try await apiService.fetchData(fromEndpoint: endpoint) else { return }
        for dto in answer.items {
            try upsert(dto, of: work, owner: owner)
        }
    }

    /// Updates the item in place when the store holds it, so open screens stay on it, and
    /// inserts it otherwise. Shelves are synced before inventories, so its étagères are there.
    private func upsert(
        _ dto: ItemDTO,
        of work: Work,
        owner: User
    ) throws {
        let itemID: String = dto._id
        let shelfIDs: [String] = dto.shelves ?? []
        let shelves: [Shelf] = shelfIDs.isEmpty ? [] : (try? modelContext.fetch(FetchDescriptor<Shelf>(predicate: #Predicate { shelfIDs.contains($0._id) }))) ?? []

        if let item = try? modelContext.fetch(FetchDescriptor<InventoryItem>(predicate: #Predicate { $0._id == itemID })).first {
            guard inFlightWrites.contains(item.persistentModelID) == false else { return }
            item.update(from: dto, forUser: owner, apiService: apiService)
            item.shelves = shelves
            item.edition?.mergeWorks([work])
            item.edition?.mergeAuthorNames(from: dto.snapshot)
        } else {
            let edition: Edition = try modelContext.edition(uri: dto.entity, snapshot: dto.snapshot, apiService: apiService)
            let item: InventoryItem = .init(itemDTO: dto, forUser: owner, edition: edition)
            item.shelves = shelves
            edition.mergeWorks([work])
            modelContext.insert(item)
        }
    }

    private func save(
        _ progress: InventorySyncProgress,
        reportingTo continuation: AsyncStream<InventorySyncProgress>.Continuation
    ) throws {
        try modelContext.save()
        continuation.yield(progress)
    }
}
