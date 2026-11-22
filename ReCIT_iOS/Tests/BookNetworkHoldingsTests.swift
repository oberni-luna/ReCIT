//
//  BookNetworkHoldingsTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 22/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct BookNetworkHoldingsTests {
    private static func entries(
        _ lists: [EntityList],
        friends: [User],
        in context: ModelContext
    ) -> [BookListEntry] {
        let items: [EntityListItem] = lists.map { list in
            context.insert(list)
            let item: EntityListItem = .init(
                _id: "\(list._id)-wd:Q1",
                uri: "wd:Q1",
                ordinal: "0",
                created: .init(timeIntervalSince1970: 0),
                itemType: .work
            )
            context.insert(item)
            list.elements.append(item)
            return item
        }
        return BookListEntry.entries(items: items, myUserId: "me", friends: friends)
    }

    @Test
    func `counts the other readers' copies and my friends' lists`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = Fixture.edition()
        context.insert(edition)
        let copies: [InventoryItem] = [
            Fixture.inventoryItem(id: "mine", ownerId: "me", edition: edition),
            Fixture.inventoryItem(id: "lea", ownerId: "lea", edition: edition),
            Fixture.inventoryItem(id: "remi", ownerId: "remi", edition: edition)
        ]
        copies.forEach(context.insert)
        let lea: User = Fixture.user(id: "lea", username: "lea", relation: .friend)
        let lists: [BookListEntry] = Self.entries(
            [.mock(id: "my-list", creatorId: "me"), .mock(id: "lea-list", creatorId: "lea")],
            friends: [lea],
            in: context
        )

        let holdings: BookNetworkHoldings = .init(copies: copies, lists: lists, myUserId: "me")

        #expect(holdings.copies.map(\._id) == ["lea", "remi"])
        #expect(holdings.lists.map(\.list._id) == ["lea-list"])
        #expect(holdings.count == 3)
        #expect(holdings.isEmpty == false)
    }

    @Test
    func `is empty when only I hold the book`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = Fixture.edition()
        context.insert(edition)
        let mine: InventoryItem = Fixture.inventoryItem(id: "mine", ownerId: "me", edition: edition)
        context.insert(mine)
        let lists: [BookListEntry] = Self.entries([.mock(id: "my-list", creatorId: "me")], friends: [], in: context)

        let holdings: BookNetworkHoldings = .init(copies: [mine], lists: lists, myUserId: "me")

        #expect(holdings.isEmpty)
    }

    @Test
    func `drops a copy once it is deleted`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = Fixture.edition()
        context.insert(edition)
        let kept: InventoryItem = Fixture.inventoryItem(id: "kept", ownerId: "lea", edition: edition)
        let removed: InventoryItem = Fixture.inventoryItem(id: "removed", ownerId: "remi", edition: edition)
        [kept, removed].forEach(context.insert)
        try context.save()

        context.delete(removed)
        try context.save()

        let holdings: BookNetworkHoldings = .init(copies: [kept, removed], lists: [], myUserId: "me")

        #expect(holdings.copies.map(\._id) == ["kept"])
        #expect(holdings.count == 1)
    }
}
