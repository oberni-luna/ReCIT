//
//  ListModel+Upsert.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData

extension ListModel {
    /// Upserts lists read from inventaire.io in place, matched by `_id`, so an open list view
    /// keeps its object. Does not save.
    /// - Parameters:
    ///   - dtos: The lists as inventaire.io sent them.
    ///   - deleteMissing: Whether stored lists absent from `dtos` are deleted.
    ///   - scope: The stored lists the deletion pass may touch.
    ///   - modelContext: The store the lists are written to.
    /// - Returns: The stored lists, in the order of `dtos`.
    /// - Throws: The store's error when it cannot be read.
    func upsertLists(
        _ dtos: [ListDTO],
        deleteMissing: Bool = false,
        scope: (EntityList) -> Bool = { _ in true },
        modelContext: ModelContext
    ) throws -> [EntityList] {
        let baseUrl: String = apiService.baseUrl()
        return try modelContext.upsert(
            dtos,
            dtoID: { $0._id },
            modelID: { (list: EntityList) in list._id },
            make: { EntityList(listDTO: $0, baseUrl: baseUrl) },
            update: { list, dto in list.update(listDTO: dto, baseUrl: baseUrl, modelContext: modelContext) },
            deleteMissing: deleteMissing,
            scope: scope
        )
    }
}
