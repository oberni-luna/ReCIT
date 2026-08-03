//
//  RemoteUpsert.swift
//  ReCIT_iOS
//
//  Server → App merge helper. Upserts decoded DTOs into the local SwiftData
//  store by identity, updating existing objects in place rather than
//  delete-and-reinsert. Preserving object identity is what keeps already-rendered
//  views reactive across a background sync.
//

import Foundation
import SwiftData

extension ModelContext {
    /// Merges `dtos` into the store for model type `M`.
    ///
    /// - Parameters:
    ///   - dtoID: Server id of a DTO.
    ///   - modelID: Local id of a persisted model (usually `\._id`).
    ///   - make: Builds a new model for a DTO with no local match.
    ///   - update: Merges a DTO into its existing local model in place.
    ///   - deleteMissing: When true, deletes local models absent from `dtos`.
    /// - Returns: The models corresponding to `dtos`, in order.
    ///
    /// Note: `make` is synchronous, so this fits models whose mapping needs no
    /// async relationship resolution. Models that must fetch related entities
    /// (e.g. transactions resolving users/items) keep their bespoke upsert.
    @discardableResult
    func upsert<M: PersistentModel, DTO>(
        _ dtos: [DTO],
        dtoID: (DTO) -> String,
        modelID: (M) -> String,
        make: (DTO) -> M,
        update: (M, DTO) -> Void,
        deleteMissing: Bool = false
    ) throws -> [M] {
        let existing: [M] = try fetch(FetchDescriptor<M>())
        var byID: [String: M] = .init(minimumCapacity: existing.count)
        for model in existing {
            byID[modelID(model)] = model
        }

        var seen: Set<String> = []
        var result: [M] = []
        for dto in dtos {
            let key: String = dtoID(dto)
            seen.insert(key)
            if let model = byID[key] {
                update(model, dto)
                result.append(model)
            } else {
                let model: M = make(dto)
                insert(model)
                byID[key] = model
                result.append(model)
            }
        }

        if deleteMissing {
            for model in existing where !seen.contains(modelID(model)) {
                delete(model)
            }
        }

        return result
    }
}
