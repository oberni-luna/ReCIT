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
    @Test
    func `shows mine by name, my friends' the most recently changed first, and leaves a stranger's out`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let lea: User = Fixture.user(id: "lea", username: "lea", relation: .friend)
        let ines: User = Fixture.user(id: "ines", username: "ines", relation: .friend)
        let lists: [EntityList] = [
            .mock(id: "b", name: "Livres lus", creatorId: "me"),
            .mock(id: "a", name: "Livres à lire", creatorId: nil),
            .mock(id: "lea-old", updated: .init(timeIntervalSince1970: 100), creatorId: "lea"),
            .mock(id: "ines-new", updated: .init(timeIntervalSince1970: 300), creatorId: "ines"),
            .mock(id: "lea-new", updated: .init(timeIntervalSince1970: 200), creatorId: "lea"),
            .mock(id: "stranger", updated: .init(timeIntervalSince1970: 400), creatorId: "stranger")
        ]
        lists.forEach(context.insert)

        let sections: ListsTabSections = .init(lists: lists, myUserId: "me", friends: [lea, ines])

        #expect(sections.mine.map(\._id) == ["a", "b"])
        #expect(sections.network.map(\.list._id) == ["ines-new", "lea-new", "lea-old"])
        #expect(sections.network.map(\.owner._id) == ["ines", "lea", "lea"])
    }

    @Test
    func `keeps the lists matching the search in both sections`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let lists: [EntityList] = [
            .mock(id: "mine-polar", name: "Polars à lire", creatorId: "me"),
            .mock(id: "mine-other", name: "Livres lus", creatorId: "me"),
            .mock(id: "lea-polar", name: "Polars nordiques", creatorId: "lea"),
            .mock(id: "lea-other", name: "Pour les enfants", creatorId: "lea")
        ]
        lists.forEach(context.insert)

        let sections: ListsTabSections = .init(
            lists: lists,
            myUserId: "me",
            friends: [Fixture.user(id: "lea", username: "lea", relation: .friend)],
            searchText: "polar"
        )

        #expect(sections.mine.map(\._id) == ["mine-polar"])
        #expect(sections.network.map(\.list._id) == ["lea-polar"])
    }

    @Test
    func `drops my list once it is deleted and saved`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let kept: EntityList = .mock(id: "kept", creatorId: "me")
        let deleted: EntityList = .mock(id: "deleted", creatorId: "me")
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
        let kept: EntityList = .mock(id: "kept", creatorId: "me")
        let deleted: EntityList = .mock(id: "deleted", creatorId: "me")
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
        let kept: EntityList = .mock(id: "lea-kept", name: "Polars nordiques", creatorId: "lea")
        let deleted: EntityList = .mock(id: "lea-deleted", name: "Polars anglais", creatorId: "lea")
        context.insert(kept)
        context.insert(deleted)
        try context.save()

        context.delete(deleted)
        try context.save()

        let sections: ListsTabSections = .init(
            lists: [deleted, kept],
            myUserId: "me",
            friends: [Fixture.user(id: "lea", username: "lea", relation: .friend)],
            searchText: "polar"
        )

        #expect(sections.mine.isEmpty)
        #expect(sections.network.count == 1)
        #expect(sections.network.first?.list === kept)
    }
}
