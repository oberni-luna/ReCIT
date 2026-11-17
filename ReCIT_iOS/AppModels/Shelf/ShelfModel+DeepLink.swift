//
//  ShelfModel+DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData

extension ShelfModel {
    /// Reads an étagère the store does not hold from inventaire.io, and upserts it beside the others
    /// when one of `owners` owns it, holding those of its books the store holds. Anyone else's is not
    /// stored: its books would be taken for mine or a friend's by the local search and « Chez mes
    /// amis ». Its books are read first, then the étagère and its books are written in one save: when
    /// reading them fails, the store is left as it was.
    /// - Parameters:
    ///   - id: The étagère's inventaire.io id.
    ///   - owners: The readers whose étagères may enter the store: me and my friends.
    ///   - modelContext: The store the étagère is written to.
    /// - Returns: The stored étagère, or `nil` when it is not one of `owners`'.
    /// - Throws: A `NetworkError`, `badStatus` 404 when the étagère is unknown, 401 when it is not
    ///   mine to see.
    func fetchShelf(
        id: String,
        ownedByOneOf owners: Set<String>,
        modelContext: ModelContext
    ) async throws -> Shelf? {
        let answer: ShelvesResponseDTO? = try await apiService.fetchData(fromEndpoint: "/api/shelves/by-ids?ids=\(id)")
        guard let dto = answer?.shelves[id], owners.contains(dto.owner) else { return nil }

        let itemIds: [String] = try await fetchItemIds(ofShelves: [id])[id] ?? []
        let shelves: [Shelf] = try modelContext.upsert(
            [dto],
            dtoID: { $0._id },
            modelID: { (shelf: Shelf) in shelf._id },
            make: { Shelf(dto: $0) },
            update: { shelf, dto in shelf.update(from: dto) }
        )
        let shelf: Shelf? = shelves.first
        shelf?.items = localItems(ids: itemIds, modelContext: modelContext)
        try modelContext.save()
        return shelf
    }
}
