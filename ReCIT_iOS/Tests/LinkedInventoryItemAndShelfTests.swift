//
//  LinkedInventoryItemAndShelfTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("A linked copy or étagère", .serialized)
struct LinkedInventoryItemAndShelfTests {
    private static let itemId: String = "d3e1127cfc074506949a3c9396e4bccb"
    private static let shelfId: String = "2b8c1752cc1195dafc3a8910f80822df"
    private static let myId: String = "me"
    private static let friend: String = "lea"
    private static let membershipAnswer: String = #"""
        { "shelves": { "\#(shelfId)": { "_id": "\#(shelfId)", "items": ["held", "not-held"] } } }
        """#

    private static func itemsAnswer(_ ids: [String]) -> String {
        let items: [String] = ids.map { id in
            """
            {
              "_id": "\(id)", "_rev": "1-a", "entity": "inv:edition", "transaction": "inventorying",
              "owner": "stranger", "created": 1794847874207,
              "snapshot": { "entity:title": "The book of irish songs" }
            }
            """
        }
        return #"{ "items": [\#(items.joined(separator: ","))], "total": \#(ids.count), "offset": 0 }"#
    }

    private static func shelfAnswer(owner: String) -> String {
        """
        {
          "shelves": {
            "\(shelfId)": {
              "_id": "\(shelfId)", "_rev": "1-a", "name": "manga", "description": "",
              "owner": "\(owner)", "color": "#1685d6", "created": 1785835874285
            }
          }
        }
        """
    }

    @Test
    func `a copy the store holds opens the book on it without asking inventaire.io`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: Self.itemId, ownerId: Self.friend, edition: Fixture.edition())
        context.insert(item)
        try context.save()
        let mock: MockAPIService = .init()
        let model: InventoryModel = .init(apiService: mock)

        let destination: NavigationDestination? = await .linkedItem(id: Self.itemId, inventoryModel: model, modelContext: context)

        #expect(destination == .book(anchor: .item(item)))
        #expect(mock.recordedRequests.isEmpty)
    }

    @Test
    func `a copy the store does not hold opens the book of its edition and stores nothing`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/items/by-ids", json: Self.itemsAnswer([Self.itemId]))
        let model: InventoryModel = .init(apiService: mock)

        let destination: NavigationDestination? = await .linkedItem(id: Self.itemId, inventoryModel: model, modelContext: context)

        #expect(destination == .book(anchor: .edition(uri: "inv:edition")))
        #expect(try context.fetch(FetchDescriptor<InventoryItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Edition>()).isEmpty)
    }

    @Test
    func `a copy inventaire.io does not show opens nothing`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/items/by-ids", json: Self.itemsAnswer([]))
        let model: InventoryModel = .init(apiService: mock)

        let destination: NavigationDestination? = await .linkedItem(id: Self.itemId, inventoryModel: model, modelContext: context)

        #expect(destination == nil)
    }

    @Test
    func `an étagère the store holds opens without asking inventaire.io`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(Shelf.mock(id: Self.shelfId, ownerId: Self.friend))
        try context.save()
        let mock: MockAPIService = .init()

        let destination: NavigationDestination? = await .linkedShelf(
            id: Self.shelfId,
            ownedByOneOf: [Self.myId],
            shelfModel: ShelfModel(apiService: mock),
            modelContext: context
        )

        #expect(destination == .shelf(id: Self.shelfId))
        #expect(mock.recordedRequests.isEmpty)
    }

    @Test
    func `a friend's étagère not synced yet is stored with the books the store holds`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(Fixture.inventoryItem(id: "held", ownerId: Self.friend, edition: Fixture.edition()))
        try context.save()
        let mock: MockAPIService = .init()
        mock.stub("/api/shelves/by-ids", json: Self.shelfAnswer(owner: Self.friend))
        mock.stub("action=by-ids", json: Self.membershipAnswer)

        let destination: NavigationDestination? = await .linkedShelf(
            id: Self.shelfId,
            ownedByOneOf: [Self.myId, Self.friend],
            shelfModel: ShelfModel(apiService: mock),
            modelContext: context
        )

        #expect(destination == .shelf(id: Self.shelfId))
        let shelf: Shelf = try #require(try context.fetch(FetchDescriptor<Shelf>()).first)
        #expect(shelf.ownerId == Self.friend)
        #expect(shelf.items.map(\._id) == ["held"])
    }

    @Test
    func `a stranger's étagère falls back to inventaire.io and stores nothing`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/shelves/by-ids", json: Self.shelfAnswer(owner: "stranger"))
        mock.stub("action=by-ids", json: Self.membershipAnswer)

        let destination: NavigationDestination? = await .linkedShelf(
            id: Self.shelfId,
            ownedByOneOf: [Self.myId, Self.friend],
            shelfModel: ShelfModel(apiService: mock),
            modelContext: context
        )

        #expect(destination == nil)
        #expect(try context.fetch(FetchDescriptor<Shelf>()).isEmpty)
        #expect(mock.recordedRequests.map(\.endpoint) == ["/api/shelves/by-ids?ids=\(Self.shelfId)"])
    }

    @Test
    func `an étagère inventaire.io refuses falls back to inventaire.io`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/shelves/by-ids", error: NetworkError.badStatus(code: 401, message: "unauthorized shelves access"))

        let destination: NavigationDestination? = await .linkedShelf(
            id: Self.shelfId,
            ownedByOneOf: [Self.myId],
            shelfModel: ShelfModel(apiService: mock),
            modelContext: context
        )

        #expect(destination == nil)
        #expect(try context.fetch(FetchDescriptor<Shelf>()).isEmpty)
    }
}
