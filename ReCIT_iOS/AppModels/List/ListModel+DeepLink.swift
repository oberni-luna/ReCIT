//
//  ListModel+DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData

extension ListModel {
    /// The list `id` names, as the store holds it; `nil` when it does not, or holds it no more.
    /// - Parameters:
    ///   - id: The list's inventaire.io id.
    ///   - modelContext: The store to read.
    /// - Returns: The stored list, or `nil`.
    /// - Throws: The store's error when it cannot be read.
    func storedList(
        id: String,
        modelContext: ModelContext
    ) throws -> EntityList? {
        let descriptor: FetchDescriptor<EntityList> = .init(predicate: #Predicate { $0._id == id })
        return try modelContext.fetch(descriptor).first(where: \.isStillInTheStore)
    }

    /// Reads one list and its elements from inventaire.io, whoever made it, and upserts it beside
    /// the others without pruning any. It is stamped with its creator, so a stranger's list is
    /// never taken for mine (`EntityList.isCreated(byMe:)`): an answer that does not name one is
    /// not stored.
    /// - Parameters:
    ///   - id: The list's inventaire.io id.
    ///   - modelContext: The store the list is written to.
    /// - Returns: The stored list, or `nil` when the answer holds no list with a creator.
    /// - Throws: A `NetworkError`, `badStatus` 404 when the list is unknown or not mine to see.
    func fetchList(
        id: String,
        modelContext: ModelContext
    ) async throws -> EntityList? {
        let answer: ListsByIdDTO? = try await apiService.fetchData(
            fromEndpoint: "/api/lists/by-ids?ids=\(id)&with-elements=true"
        )
        guard let dto = answer?.lists[id], dto.creator != nil else { return nil }

        let baseUrl: String = apiService.baseUrl()
        let lists: [EntityList] = try modelContext.upsert(
            [dto],
            dtoID: { $0._id },
            modelID: { (list: EntityList) in list._id },
            make: { EntityList(listDTO: $0, baseUrl: baseUrl) },
            update: { list, dto in list.update(listDTO: dto, baseUrl: baseUrl, modelContext: modelContext) }
        )
        try modelContext.save()
        return lists.first
    }
}
