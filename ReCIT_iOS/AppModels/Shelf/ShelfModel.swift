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
final class ShelfModel {

    /// DEV: when true, shelf membership is faked by distributing the user's own items
    /// across their shelves, so the bookshelf UI can be validated independently of the
    /// `/api/shelves` membership call. Now using real server membership.
    static let useFakeMembership: Bool = false

    private let apiService: APIServicing

    /// Shared channel used to surface a background failure to the UI.
    var errorReporter: AppErrorReporter?

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
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

        // 2. Membership.
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
