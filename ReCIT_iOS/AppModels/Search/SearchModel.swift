//
//  SearchModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import SwiftData
import Foundation
import Combine

class SearchModel: ObservableObject {
    private let apiService: APIService

    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    func searchLocalInventory(query: String, modelContext: ModelContext) -> [SearchResult] {
        let cleanQuery: String = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let predicate: Predicate<InventoryItem> = #Predicate { item in
            item.searchIndex.localizedStandardContains(cleanQuery)
        }
        let items: [InventoryItem] = (try? modelContext.fetch(.init(predicate: predicate))) ?? []

        var seenUris: Set<String> = []
        return items.compactMap { item in
            guard let edition = item.edition else { return nil }
            guard seenUris.insert(edition.uri).inserted else { return nil }
            return .init(
                id: edition.uri,
                uri: edition.uri,
                title: edition.title,
                description: edition.authorNames.joined(separator: ", "),
                imageUrl: edition.image,
                score: 0,
                type: .inventoryItem,
                localItem: item
            )
        }
    }

    func searchEntity(query: String, lang: String? = "fr", limit: Int = 15, offset: Int = 0) async throws -> [SearchResult] {
        let trimmedQuery: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        let language: String = lang ?? "fr"
        let endpoint: String = "/api/search?types=humans|works&search=\(trimmedQuery)&lang=\(language)&limit=\(limit)&offset=\(offset)&exact=false"

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
