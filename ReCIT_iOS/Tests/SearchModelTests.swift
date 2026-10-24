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
            { "id": "a", "type": "works", "uri": "wd:Q1", "label": "Low", "description": "d1", "image": "/img/a.jpg", "_score": 1.0 },
            { "id": "b", "type": "humans", "uri": "wd:Q2", "label": "High", "description": null, "image": null, "_score": 9.0 }
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
            queryValue("types", in: request.endpoint) ?? ""
        }

        #expect(types == ["works", "humans", "humans|works"])
    }

    @Test("A query with a space or an accent reaches the server as typed, not encoded twice")
    func remoteSearchEncodesTheQueryOnce() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/search", json: #"{ "results": [] }"#)
        let model: SearchModel = .init(apiService: mock)

        _ = try await model.searchEntity(query: "Émile Zola")

        let endpoint: String = try #require(mock.recordedRequests.first?.endpoint)
        #expect(queryValue("search", in: endpoint) == "Émile Zola")
        #expect(queryValue("types", in: endpoint) == "humans|works")
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

    /// What the server reads for `name`, once the endpoint has gone through `URL(string:)` the
    /// way `APIService` sends it. The mock records the endpoint before that step, so reading it
    /// raw would miss an endpoint the conversion encodes a second time.
    private func queryValue(
        _ name: String,
        in endpoint: String
    ) -> String? {
        guard let url = URL(string: "https://test.local\(endpoint)") else { return nil }

        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
