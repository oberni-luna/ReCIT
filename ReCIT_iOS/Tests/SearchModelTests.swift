//
//  SearchModelTests.swift
//  ReCIT_iOSTests
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("SearchModel", .serialized)
struct SearchModelTests {

    @Test("Local search matches the pre-computed index")
    func localSearchMatches() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = Fixture.edition(uri: "isbn:1", title: "Harry Potter")
        let match: InventoryItem = Fixture.inventoryItem(
            id: "i1",
            edition: edition,
            searchIndex: "tester rowling harry potter"
        )
        let other: InventoryItem = Fixture.inventoryItem(
            id: "i2",
            edition: Fixture.edition(uri: "isbn:2", title: "Dune"),
            searchIndex: "tester herbert dune"
        )
        context.insert(match)
        context.insert(other)
        try context.save()

        let model: SearchModel = .init(apiService: MockAPIService())
        let results: [SearchResult] = model.searchLocalInventory(query: "harry", modelContext: context)

        #expect(results.count == 1)
        #expect(results.first?.uri == "isbn:1")
        #expect(results.first?.type == .inventoryItem)
    }

    @Test("Local search deduplicates items sharing the same edition")
    func localSearchDeduplicates() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = Fixture.edition(uri: "isbn:1", title: "Harry Potter")
        let first: InventoryItem = Fixture.inventoryItem(id: "i1", edition: edition, searchIndex: "harry potter")
        let second: InventoryItem = Fixture.inventoryItem(id: "i2", edition: edition, searchIndex: "harry potter")
        context.insert(first)
        context.insert(second)
        try context.save()

        let model: SearchModel = .init(apiService: MockAPIService())
        let results: [SearchResult] = model.searchLocalInventory(query: "harry", modelContext: context)

        #expect(results.count == 1)
    }

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

    @Test("Remote search returns empty for a blank query without hitting the network")
    func remoteSearchBlankQuery() async throws {
        let mock: MockAPIService = .init()
        let model: SearchModel = .init(apiService: mock)

        let results: [SearchResult] = try await model.searchEntity(query: "   ")

        #expect(results.isEmpty)
        #expect(mock.recordedRequests.isEmpty)
    }
}
