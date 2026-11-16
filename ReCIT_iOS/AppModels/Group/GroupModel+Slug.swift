//
//  GroupModel+Slug.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension GroupModel {
    /// The id of the group inventaire.io knows under `slug`. Nothing is stored: the group's screen
    /// reads it afresh on arrival, as it does for a group found by name.
    /// - Parameter slug: A slug as a link spells it, already checked against inventaire.io's rule.
    /// - Returns: The group's id.
    /// - Throws: A `NetworkError`, among them the `404` of a slug no group has.
    func groupId(slug: String) async throws -> String {
        guard let answer: GroupByIdDTO = try await apiService.fetchData(
            fromEndpoint: "/api/groups/by-slug?slug=\(slug)"
        ) else {
            throw NetworkError.badResponse
        }
        return answer.group._id
    }
}
