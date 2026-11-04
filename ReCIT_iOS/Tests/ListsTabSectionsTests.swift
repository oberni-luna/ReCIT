//
//  ListsTabSectionsTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 04/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct ListsTabSectionsTests {
    private static func list(
        id: String,
        creator: String
    ) -> EntityList {
        .init(
            _id: id,
            _rev: "1",
            name: id,
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            visibility: [.public],
            type: .work,
            creatorId: creator
        )
    }

    private static func friend(_ id: String) -> User {
        let user: User = Fixture.user(id: id, username: id)
        user.relation = .friend
        return user
    }

    @Test
    func `drops my list once it is deleted and saved`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let kept: EntityList = Self.list(id: "kept", creator: "me")
        let deleted: EntityList = Self.list(id: "deleted", creator: "me")
        context.insert(kept)
        context.insert(deleted)
        try context.save()

        context.delete(deleted)
        try context.save()

        let sections: ListsTabSections = .init(lists: [kept, deleted], myUserId: "me", friends: [])

        #expect(sections.mine.count == 1)
        #expect(sections.mine.first === kept)
    }

    @Test
    func `drops my list between its deletion and the save`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let kept: EntityList = Self.list(id: "kept", creator: "me")
        let deleted: EntityList = Self.list(id: "deleted", creator: "me")
        context.insert(kept)
        context.insert(deleted)
        try context.save()

        context.delete(deleted)

        let sections: ListsTabSections = .init(lists: [deleted, kept], myUserId: "me", friends: [])

        #expect(sections.mine.count == 1)
        #expect(sections.mine.first === kept)
    }

    @Test
    func `drops a friend's deleted list while searching`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let kept: EntityList = Self.list(id: "lea-kept", creator: "lea")
        let deleted: EntityList = Self.list(id: "lea-deleted", creator: "lea")
        context.insert(kept)
        context.insert(deleted)
        try context.save()

        context.delete(deleted)
        try context.save()

        let sections: ListsTabSections = .init(
            lists: [deleted, kept],
            myUserId: "me",
            friends: [Self.friend("lea")],
            searchText: "lea"
        )

        #expect(sections.mine.isEmpty)
        #expect(sections.network.count == 1)
        #expect(sections.network.first?.list === kept)
    }
}
