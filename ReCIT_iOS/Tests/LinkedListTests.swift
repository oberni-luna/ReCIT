//
//  LinkedListTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("A linked list", .serialized)
struct LinkedListTests {
    private static let listId: String = "88b00676d608d9d53c5974fd9bc1009a"

    private static func insertList(
        holding elements: [(id: String, uri: String)],
        in context: ModelContext
    ) -> EntityList {
        let list: EntityList = .mock(id: listId, creatorId: "lea")
        context.insert(list)
        let items: [EntityListItem] = elements.map { element in
            .init(
                _id: element.id,
                uri: element.uri,
                ordinal: "0",
                created: .init(timeIntervalSince1970: 0),
                itemType: .work
            )
        }
        items.forEach(context.insert)
        list.elements.append(contentsOf: items)
        return list
    }

    private static func answer(creator: String?) -> String {
        let creatorField: String = creator.map { #""creator": "\#($0)","# } ?? ""
        return """
        {
          "lists": {
            "\(listId)": {
              "_id": "\(listId)", "_rev": "3-abc", "name": "Recommandés", "description": "",
              "visibility": ["public"], \(creatorField)
              "created": 1725884555199, "type": "work", "updated": 1768568673210,
              "elements": [
                {
                  "_id": "e1", "_rev": "1-a", "list": "\(listId)", "uri": "wd:Q1",
                  "created": 1725954737503, "ordinal": "1110i"
                }
              ]
            }
          }
        }
        """
    }

    @Test
    func `an element id opens the list on that element's entity`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = Self.insertList(
            holding: [(id: "e1", uri: "wd:Q1"), (id: "e2", uri: "wd:Q2"), (id: "e3", uri: "wd:Q3")],
            in: context
        )

        #expect(NavigationDestination(linkedList: list, elementId: "e3") == .entityList(id: Self.listId, focusURI: "wd:Q3"))
    }

    @Test
    func `an element gone from the list or none at all opens it on its first element`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = Self.insertList(holding: [(id: "e1", uri: "wd:Q1")], in: context)

        #expect(NavigationDestination(linkedList: list, elementId: "gone") == .entityList(id: Self.listId, focusURI: nil))
        #expect(NavigationDestination(linkedList: list, elementId: nil) == .entityList(id: Self.listId, focusURI: nil))
    }

    @Test
    func `a fetched list is stored with its creator and its elements beside the others`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(EntityList.mock(id: "mine", creatorId: "me"))
        try context.save()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-ids", json: Self.answer(creator: "stranger"))

        let list: EntityList? = try await ListModel(apiService: mock).fetchList(id: Self.listId, modelContext: context)

        #expect(list?.creatorId == "stranger")
        #expect(list?.isCreated(byMe: "me") == false)
        #expect(list?.elements.map(\._id) == ["e1"])
        let stored: Set<String> = .init(try context.fetch(FetchDescriptor<EntityList>()).map(\._id))
        #expect(stored == ["mine", Self.listId])
    }

    @Test
    func `a fetched list that names no creator is not stored`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-ids", json: Self.answer(creator: nil))

        let list: EntityList? = try await ListModel(apiService: mock).fetchList(id: Self.listId, modelContext: context)

        #expect(list == nil)
        #expect(try context.fetch(FetchDescriptor<EntityList>()).isEmpty)
    }

    @Test
    func `a list inventaire.io does not show throws`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-ids", error: NetworkError.badStatus(code: 404, message: "not found"))

        await #expect(throws: NetworkError.self) {
            try await ListModel(apiService: mock).fetchList(id: Self.listId, modelContext: context)
        }
    }

    @Test
    func `a stored list is read from the store`() throws {
        let context: ModelContext = try TestStore.makeContext()
        _ = Self.insertList(holding: [], in: context)
        try context.save()
        let model: ListModel = .init(apiService: MockAPIService())

        #expect(try model.storedList(id: Self.listId, modelContext: context)?._id == Self.listId)
        #expect(try model.storedList(id: "unknown", modelContext: context) == nil)
    }
}
