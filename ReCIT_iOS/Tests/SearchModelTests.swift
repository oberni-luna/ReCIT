//
//  SearchModelTests.swift
//  ReCIT_iOSTests
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("SearchModel", .serialized)
struct SearchModelTests {

    @Test("Remote search maps DTOs and sorts by descending score")
    func remoteSearchMapsAndSorts() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/search", json: """
        {
          "results": [
            { "id": "a", "type": "works", "uri": "wd:Q1", "label": "Low", "description": "d1", "image": "/img/a.jpg", "score": 1.0 },
            { "id": "b", "type": "humans", "uri": "wd:Q2", "label": "High", "description": null, "image": null, "score": 9.0 }
          ]
        }
        """)

        let model: SearchModel = .init(apiService: mock)
        let results: [SearchResult] = try await model.searchEntity(query: "hugo")

        #expect(results.count == 2)
        #expect(results.first?.title == "High")
        #expect(results.first?.type == .humans)
        #expect(results.last?.title == "Low")
    }

    @Test("A suggestion's entity types are the ones the request asks for")
    func remoteSearchAsksForTheSuggestedTypes() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/search", json: #"{ "results": [] }"#)
        let model: SearchModel = .init(apiService: mock)

        for suggestion in SearchSuggestion.suggestions(for: "monte cristo") {
            _ = try await model.searchEntity(query: suggestion.query, entityTypes: suggestion.entityTypes)
        }

        let types: [String] = mock.recordedRequests.map { request in
            request.endpoint
                .split(separator: "?").last.map(String.init)?
                .split(separator: "&")
                .first(where: { $0.hasPrefix("types=") })
                .map { String($0.dropFirst("types=".count)) } ?? ""
        }

        #expect(types == ["works", "humans", "humans|works"])
    }

    @Test("A query carrying an ampersand reaches the server whole")
    func remoteSearchEncodesTheQuery() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/search", json: #"{ "results": [] }"#)
        let model: SearchModel = .init(apiService: mock)

        _ = try await model.searchEntity(query: "rosencrantz & guildenstern")

        let endpoint: String = try #require(mock.recordedRequests.first?.endpoint)
        #expect(endpoint.contains("search=rosencrantz%20%26%20guildenstern"))
        #expect(endpoint.contains("&lang="))
    }

    @Test("Remote search returns empty for a blank query without hitting the network")
    func remoteSearchBlankQuery() async throws {
        let mock: MockAPIService = .init()
        let model: SearchModel = .init(apiService: mock)

        let results: [SearchResult] = try await model.searchEntity(query: "   ")

        #expect(results.isEmpty)
        #expect(mock.recordedRequests.isEmpty)
    }
}
