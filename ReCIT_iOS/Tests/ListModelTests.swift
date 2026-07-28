//
//  ListModelTests.swift
//  ReCIT_iOSTests
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("ListModel", .serialized)
struct ListModelTests {

    private func newListJSON(id: String, name: String) -> String {
        """
        {
          "list": {
            "_id": "\(id)",
            "_rev": "1-abc",
            "name": "\(name)",
            "description": "desc",
            "created": 1700000000,
            "updated": null,
            "visibility": ["public"],
            "type": "work",
            "elements": []
          }
        }
        """
    }

    @Test("createList persists the returned list")
    func createListPersists() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists", json: newListJSON(id: "list-1", name: "Favourites"))
        let model: ListModel = .init(apiService: mock)

        try await model.createList(
            modelContext: context,
            name: "Favourites",
            description: "desc",
            type: "work",
            visibility: ["public"]
        )

        let stored: [EntityList] = try context.fetch(FetchDescriptor<EntityList>())
        #expect(stored.count == 1)
        #expect(stored.first?.name == "Favourites")
        #expect(stored.first?._id == "list-1")
    }

    @Test("deleteList removes the list on a successful response")
    func deleteListRemoves() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = .init(
            _id: "list-1",
            _rev: "1",
            name: "Favourites",
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            visibility: [.public],
            type: .work
        )
        context.insert(list)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/delete", json: #"{"ok":true}"#)
        let model: ListModel = .init(apiService: mock)

        try await model.deleteList(modelContext: context, list: list)

        let stored: [EntityList] = try context.fetch(FetchDescriptor<EntityList>())
        #expect(stored.isEmpty)
    }
}
