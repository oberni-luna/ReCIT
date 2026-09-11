//
//  SearchModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import Foundation

@MainActor
@Observable
final class SearchModel {
    private let apiService: APIServicing

    init(apiService: APIServicing) {
        self.apiService = apiService
    }

    /// Searches inventaire.io for the entity types asked for — `SearchSuggestion` carries them,
    /// so the row a user tapped and the request that goes out name the same thing. The default
    /// is both, which is what a query with no suggestion behind it means.
    func searchEntity(
        query: String,
        entityTypes: [SearchResultType] = [.humans, .works],
        lang: String? = "fr",
        limit: Int = 15,
        offset: Int = 0
    ) async throws -> [SearchResult] {
        let trimmedQuery: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        let types: String = entityTypes.isEmpty
            ? "humans|works"
            : entityTypes.map(\.rawValue).joined(separator: "|")
        // A title can hold an ampersand or a plus, both of which end a query parameter and
        // would truncate the search rather than fail it.
        let search: String = trimmedQuery.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed.subtracting(.init(charactersIn: "&+=?#"))
        ) ?? trimmedQuery
        let language: String = lang ?? "fr"
        let endpoint: String = "/api/search?types=\(types)&search=\(search)&lang=\(language)&limit=\(limit)&offset=\(offset)&exact=false"

        let response: SearchResultsDTO? = try await apiService.fetchData(fromEndpoint: endpoint, debug: true)

        return response?.results.map { result in
            SearchResult(
                id: result.id,
                uri: result.uri,
                title: result.label,
                description: result.description,
                imageUrl: apiService.absoluteImageUrl(result.image),
                score: result.score ?? 0,
                type: SearchResultType(rawValue: result.type) ?? .unknown
            )
        }
        .sorted { $0.score > $1.score } ?? []
    }
}
