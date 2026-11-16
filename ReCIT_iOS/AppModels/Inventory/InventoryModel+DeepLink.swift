//
//  InventoryModel+DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension InventoryModel {
    /// The uri of the edition a copy is of, read from inventaire.io for a copy the store does not
    /// hold. Nothing of the answer is stored: a stranger's copy in the store would be found by the
    /// local search and « Chez mes amis » as mine or a friend's.
    /// - Parameter id: The copy's inventaire.io id.
    /// - Returns: The edition's uri, or `nil` when inventaire.io shows no such copy.
    /// - Throws: A `NetworkError` when inventaire.io cannot be reached.
    func fetchEditionURI(ofItem id: String) async throws -> String? {
        let answer: ItemsDTO? = try await apiService.fetchData(fromEndpoint: "/api/items/by-ids?ids=\(id)")
        return answer?.items.first { $0._id == id }?.entity
    }
}
