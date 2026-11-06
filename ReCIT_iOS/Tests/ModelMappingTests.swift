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

        let edition: Edition = .init(uri: dto.entity, entitySnapshotDTO: dto.snapshot, apiService: MockAPIService())
        let item: InventoryItem = .init(itemDTO: dto, forUser: owner, edition: edition)

        #expect(item._id == "item-42")
        #expect(item.transaction == .giving)
        #expect(item.ownerId == "owner-7")
        #expect(item.visibility == [.friends])
        #expect(item.edition?.title == "Dune")
        #expect(item.searchIndex.contains("dune"))
        #expect(item.searchIndex.contains("frank herbert"))
    }

    @Test
    func `an item reads its private note, and an empty one when the payload carries none`() throws {
        let withNote: ItemDTO = try JSONDecoder().decode(ItemDTO.self, from: Data(itemJSON(notes: #""lent to Léa""#).utf8))
        let withoutNote: ItemDTO = try JSONDecoder().decode(ItemDTO.self, from: Data(itemJSON(notes: nil).utf8))
        let owner: User = Fixture.user(username: "reader")
        let edition: Edition = .init(uri: withNote.entity, entitySnapshotDTO: withNote.snapshot, apiService: MockAPIService())

        #expect(withNote.notes == "lent to Léa")
        #expect(withoutNote.notes == nil)
        #expect(InventoryItem(itemDTO: withNote, forUser: owner, edition: edition).notes == "lent to Léa")
        #expect(InventoryItem(itemDTO: withoutNote, forUser: owner, edition: edition).notes.isEmpty)
    }

    @Test
    func `a sync takes the private note it carries, and keeps mine when it carries none`() throws {
        let owner: User = Fixture.user(username: "reader")
        let item: InventoryItem = Fixture.inventoryItem(id: "item-42", edition: Fixture.edition(uri: "isbn:123"))
        item.notes = "mine"

        let sparse: ItemDTO = try JSONDecoder().decode(ItemDTO.self, from: Data(itemJSON(notes: nil).utf8))
        item.update(from: sparse, forUser: owner, apiService: MockAPIService())
        #expect(item.notes == "mine")

        let edited: ItemDTO = try JSONDecoder().decode(ItemDTO.self, from: Data(itemJSON(notes: #""written on the site""#).utf8))
        item.update(from: edited, forUser: owner, apiService: MockAPIService())
        #expect(item.notes == "written on the site")
        #expect(item.details == "mint condition")
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
    // MARK: - Dates read off the right claim, in the right unit

    private func workDTO(claims: String) throws -> EntityResultDTO {
        let json: String = """
        {"uri":"wd:Q1","lastrevid":1,"type":"work","labels":{"fr":"Germinal"},"claims":\(claims)}
        """
        return try JSONDecoder().decode(EntityResultDTO.self, from: Data(json.utf8))
    }

    @Test("A work's publication date is its P577, not a date of death")
    func workPublicationDateIsP577() throws {
        let published: EntityResultDTO = try workDTO(claims: #"{"wdt:P577":["1885-03-02"]}"#)
        let work: Work = .init(entityDTO: published, authors: [], apiService: MockAPIService())

        let year: Int? = work.publicationDate.map { Calendar(identifier: .gregorian).component(.year, from: $0) }
        #expect(year == 1885)

        let deathOnly: EntityResultDTO = try workDTO(claims: #"{"wdt:P570":["1902-09-29"]}"#)
        #expect(Work(entityDTO: deathOnly, authors: [], apiService: MockAPIService()).publicationDate == nil)

        let fresh: Work = .init(uri: "wd:Q1", lastrevid: 0, title: "Germinal")
        fresh.update(entityDTO: published, apiService: MockAPIService())
        #expect(fresh.publicationDate == work.publicationDate)
    }

    @Test("A list's creation date is read from milliseconds")
    func listCreatedIsMilliseconds() throws {
        let json: String = """
        {"_id":"l1","_rev":"1","name":"L","description":"","created":1700000000000,"visibility":[],"type":"work"}
        """
        let dto: ListDTO = try JSONDecoder().decode(ListDTO.self, from: Data(json.utf8))

        let list: EntityList = .init(listDTO: dto, baseUrl: "")

        #expect(list.created == Date(timeIntervalSince1970: 1_700_000_000))
    }

    private func itemJSON(notes: String?) -> String {
        let notesLine: String = notes.map { #""notes": \#($0),"# } ?? ""
        return """
        {
          "_id": "item-42",
          "_rev": "3-xyz",
          "entity": "isbn:123",
          "transaction": "giving",
          "details": "mint condition",
          \(notesLine)
          "owner": "owner-7",
          "created": 1700000000000,
          "snapshot": { "entity:title": "Dune", "entity:authors": "Frank Herbert" }
        }
        """
    }
}
