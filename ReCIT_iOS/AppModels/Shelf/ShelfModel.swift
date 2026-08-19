//
//  ShelfModel.swift
//  ReCIT_iOS
//
//  Syncs the current user's inventaire.io shelves into SwiftData. Read-only (v1):
//  no create/update/delete.
//
//  Two passes: (1) `by-owners` upserts shelf metadata; (2) `by-ids&with-items`
//  rebuilds the `Shelf ⇄ InventoryItem` relation from server membership. The second
//  pass links whatever items already exist locally, so membership stays correct even
//  when the gated inventory sync skips (its own linking only runs on a real refresh).
//  See ADR 0003.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ShelfModel: OptimisticMutating {

    /// DEV: when true, shelf membership is faked by distributing the user's own items
    /// across their shelves, so the bookshelf UI can be validated independently of the
    /// `/api/shelves` membership call. Now using real server membership.
    static let useFakeMembership: Bool = false

    private let apiService: APIServicing

    /// Shared channel used to surface a background failure to the UI.
    var errorReporter: AppErrorReporter?

    /// Most recent optimistic background task, exposed so tests can await it.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    /// Raised while an optimistic membership write is waiting on the server.
    ///
    /// The `Shelf ⇄ InventoryItem` relation has two independent *wholesale* writers —
    /// `linkItems` below and `InventoryModel.syncInventory`'s per-item assignment — and
    /// both replace it outright with server state that is one round-trip behind. A sync
    /// landing in that window would visibly take the book back off the étagère the user
    /// just put it on, so both writers stand down until the write settles. App-scoped
    /// rather than instance-scoped because the two writers live in two different models.
    /// One mutation at a time, which suits menu-driven single-book actions; bulk
    /// membership writes would need a counter instead. See PRD 0004.
    private(set) static var isMembershipWriteInFlight: Bool = false

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
    }

    /// Optimistically creates a shelf: a placeholder appears at once (slotting into the
    /// A→Z order), the `POST` runs in the background, and on success the placeholder is
    /// swapped for the server's canonical shelf. On failure it's removed and the error
    /// surfaced. Visibility defaults to private server-side. See ADR 0003 / 0004.
    func createShelf(name: String, description: String, visibility: [String], ownerId: String, modelContext: ModelContext) {
        let placeholder: Shelf = .init(
            _id: OptimisticID.make(),
            _rev: "",
            name: name,
            slug: "",
            shelfDescription: description,
            ownerId: ownerId,
            visibility: visibility,
            colorHex: nil,
            created: .now,
            updated: nil
        )

        inFlightTask = optimistic(
            modelContext,
            apply: { modelContext.insert(placeholder) },
            revert: { modelContext.delete(placeholder) },
            request: { [weak self] in
                guard let self else { return }
                let payload: NewShelfDTO = .init(name: name, description: description.isEmpty ? nil : description, visibility: visibility)
                guard let response: ShelfResponseDTO = try await self.apiService.send(
                    toEndpoint: "/api/shelves?action=create",
                    method: "POST",
                    payload: payload,
                    debug: true
                ) else {
                    throw NetworkError.badResponse
                }
                // Reconcile: swap the placeholder for the server's canonical shelf.
                modelContext.delete(placeholder)
                modelContext.insert(Shelf(dto: response.shelf))
            }
        )
    }

    /// Optimistically updates a shelf's editable attributes (name, description,
    /// visibility): applies locally at once, PUTs in the background, reverts on failure.
    func updateShelf(_ shelf: Shelf, name: String, description: String, visibility: [String], modelContext: ModelContext) {
        let previousName: String = shelf.name
        let previousDescription: String = shelf.shelfDescription
        let previousVisibility: [String] = shelf.visibility

        inFlightTask = optimistic(
            modelContext,
            apply: {
                shelf.name = name
                shelf.shelfDescription = description
                shelf.visibility = visibility
            },
            revert: {
                shelf.name = previousName
                shelf.shelfDescription = previousDescription
                shelf.visibility = previousVisibility
            },
            request: { [weak self] in
                guard let self else { return }
                let payload: UpdateShelfDTO = .init(
                    shelf: shelf._id,
                    name: name,
                    description: description,
                    visibility: visibility
                )
                guard let response: ShelfResponseDTO = try await self.apiService.send(
                    toEndpoint: "/api/shelves?action=update",
                    method: "POST",
                    payload: payload,
                    debug: true
                ) else {
                    throw NetworkError.badResponse
                }
                shelf.update(from: response.shelf)
            }
        )
    }

    /// Optimistically files an item onto an étagère: the relation is mutated and saved at
    /// once, so the shelf card fills in before the network is touched, then the write runs
    /// in a model-owned background task and the server's post-write membership is
    /// reconciled back in. On failure the book comes off again and the error is surfaced.
    ///
    /// The relation declares its inverse, so appending on the shelf side moves the item
    /// side too; a book may sit on several étagères at once. Already-filed items are a
    /// no-op — the menu never offers them, this only guards against a double tap.
    /// See ADR 0001 / PRD 0004.
    func addItem(_ item: InventoryItem, to shelf: Shelf, modelContext: ModelContext) {
        let itemId: String = item._id
        guard shelf.items.contains(where: { $0._id == itemId }) == false else { return }

        Self.isMembershipWriteInFlight = true

        let cycle: Task<Void, Never> = optimistic(
            modelContext,
            apply: { shelf.items.append(item) },
            revert: { shelf.items.removeAll { $0._id == itemId } },
            request: { [weak self] in
                guard let self else { return }
                let payload: ShelfItemsDTO = .init(id: shelf._id, items: [itemId])
                guard let response: ShelvesWithItemsResponseDTO = try await self.apiService.send(
                    toEndpoint: "/api/shelves?action=add-items",
                    method: "POST",
                    payload: payload,
                    debug: true
                ) else {
                    throw NetworkError.badResponse
                }
                // Reconcile: the response carries the étagère's membership after the write.
                guard let itemIds = response.shelves[shelf._id]?.items else { return }
                shelf.items = self.localItems(ids: itemIds, modelContext: modelContext)
            }
        )

        // Lower the gate only once the whole cycle has settled — including a revert, which
        // the runner performs after `request` has thrown.
        inFlightTask = Task {
            await cycle.value
            Self.isMembershipWriteInFlight = false
        }
    }

    func syncShelves(forUser: User, modelContext: ModelContext) async throws {
        // 1. Shelf metadata (name, colour, …), upserted in place.
        let response: ShelvesResponseDTO? = try await apiService.fetchData(
            fromEndpoint: "/api/shelves?action=by-owners&owners=\(forUser._id)"
        )
        guard let response else { return }

        let dtos: [ShelfDTO] = Array(response.shelves.values)
        try modelContext.upsert(
            dtos,
            dtoID: { $0._id },
            modelID: { (shelf: Shelf) in shelf._id },
            make: { Shelf(dto: $0) },
            update: { shelf, dto in shelf.update(from: dto) },
            deleteMissing: true
        )
        try modelContext.save()

        // 2. Membership. Stand down while a membership write is still unconfirmed: this
        // pass assigns the relation wholesale from state the server has not applied the
        // user's change to yet. See PRD 0004.
        guard Self.isMembershipWriteInFlight == false else { return }

        if Self.useFakeMembership {
            applyFakeMembership(ownerId: forUser._id, modelContext: modelContext)
        } else {
            // Rebuild the relation from the authoritative server list of items per
            // shelf. Independent of the inventory-sync gate.
            try await linkItems(shelfIds: Array(response.shelves.keys), modelContext: modelContext)
        }
    }

    /// DEV fake: spreads the user's items across their shelves with varied counts so
    /// both layouts (vertical spines ≤5, horizontal pile ≥6) are exercised. Overlap
    /// is intentional (a book can sit on several shelves).
    private func applyFakeMembership(ownerId: String, modelContext: ModelContext) {
        var itemsDescriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.created, order: .reverse)]
        )
        itemsDescriptor.fetchLimit = 40
        let items: [InventoryItem] = (try? modelContext.fetch(itemsDescriptor)) ?? []
        guard items.isEmpty == false else { return }

        let shelvesDescriptor: FetchDescriptor<Shelf> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.name)]
        )
        let shelves: [Shelf] = (try? modelContext.fetch(shelvesDescriptor)) ?? []

        let counts: [Int] = [8, 4, 2, 6, 3]
        for (index, shelf) in shelves.enumerated() {
            let count: Int = min(counts[index % counts.count], items.count)
            shelf.items = Array(items.prefix(count))
        }
        try? modelContext.save()
    }

    private func linkItems(shelfIds: [String], modelContext: ModelContext) async throws {
        guard shelfIds.isEmpty == false else { return }

        let idsParam: String = shelfIds.joined(separator: "|")
        let withItems: ShelvesWithItemsResponseDTO? = try await apiService.fetchData(
            fromEndpoint: "/api/shelves?action=by-ids&ids=\(idsParam)&with-items=true"
        )
        guard let withItems else { return }

        for (shelfId, dto) in withItems.shelves {
            guard let shelf = localShelf(id: shelfId, modelContext: modelContext) else { continue }
            shelf.items = localItems(ids: dto.items ?? [], modelContext: modelContext)
        }
        try modelContext.save()
    }

    private func localShelf(id: String, modelContext: ModelContext) -> Shelf? {
        let descriptor: FetchDescriptor<Shelf> = .init(predicate: #Predicate { $0._id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func localItems(ids: [String], modelContext: ModelContext) -> [InventoryItem] {
        guard ids.isEmpty == false else { return [] }
        let descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { ids.contains($0._id) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
