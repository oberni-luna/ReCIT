//
//  ModelMappingTests.swift
//  ReCIT_iOSTests
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Model mapping & persistence", .serialized)
struct ModelMappingTests {

    @Test("buildSearchIndex lowercases, strips diacritics and joins fields")
    func searchIndexNormalises() {
        let index: String = InventoryItem.buildSearchIndex(
            ownerUsername: "Léa",
            authorNames: ["Victor Hugo"],
            title: "Les Misérables",
            subtitle: nil
        )

        #expect(index == "lea victor hugo les miserables")
    }

    @Test("ItemDTO maps onto an InventoryItem")
    func itemDTOMapping() throws {
        let json: String = """
        {
          "_id": "item-42",
          "_rev": "3-xyz",
          "entity": "isbn:123",
          "transaction": "giving",
          "details": "mint condition",
          "visibility": ["friends"],
          "owner": "owner-7",
          "created": 1700000000000,
          "updated": 1700000005000,
          "busy": false,
          "snapshot": { "entity:title": "Dune", "entity:authors": "Frank Herbert" }
        }
        """
        let dto: ItemDTO = try JSONDecoder().decode(ItemDTO.self, from: Data(json.utf8))
        let owner: User = Fixture.user(username: "reader")

        let item: InventoryItem = .init(itemDTO: dto, forUser: owner, apiService: MockAPIService())

        #expect(item._id == "item-42")
        #expect(item.transaction == .giving)
        #expect(item.ownerId == "owner-7")
        #expect(item.visibility == [.friends])
        #expect(item.edition?.title == "Dune")
        #expect(item.searchIndex.contains("dune"))
        #expect(item.searchIndex.contains("frank herbert"))
    }

    @Test("An EntityList persists together with its elements")
    func listPersistsWithElements() throws {
        let context: ModelContext = try TestStore.makeContext()
        let element: EntityListItem = .init(
            _id: "el-1",
            uri: "wd:Q1",
            ordinal: "0",
            created: .init(timeIntervalSince1970: 0),
            itemType: .work
        )
        let list: EntityList = .init(
            _id: "list-1",
            _rev: "1",
            name: "L",
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            visibility: [.public],
            elements: [element],
            type: .work
        )
        context.insert(list)
        try context.save()

        let storedLists: [EntityList] = try context.fetch(FetchDescriptor<EntityList>())
        #expect(storedLists.count == 1)
        #expect(storedLists.first?.elements.count == 1)
        #expect(try context.fetch(FetchDescriptor<EntityListItem>()).count == 1)
    }

    @Test("User.update merges every sync, since user payloads carry no revision")
    func userUpdateMergesWithoutRevision() {
        let user: User = .init(
            _id: "u1",
            _rev: "",
            username: "old",
            email: "old@example.org",
            position: nil,
            avatarURLValue: "https://example.org/old.png",
            itemCount: 3
        )

        // What `/api/user` and `/api/users/by-ids` actually return: no `_rev`, and no email
        // or picture for anyone but oneself. The count still has to move.
        let fresher: User = .init(
            _id: "u1",
            _rev: "",
            username: "new",
            email: nil,
            position: nil,
            avatarURLValue: nil,
            itemCount: 5,
            lastItemAdded: 42
        )
        user.update(with: fresher)

        #expect(user.username == "new")
        #expect(user.itemCount == 5)
        #expect(user.lastItemAdded == 42)
        // A sparse payload must not wipe good local data (ADR 0001).
        #expect(user.email == "old@example.org")
        #expect(user.avatarURLValue == "https://example.org/old.png")
    }
}
