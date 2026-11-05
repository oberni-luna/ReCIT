//
//  BookListEntriesTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 05/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct BookListEntriesTests {
    private static func insert(
        list: EntityList,
        holding uris: [String],
        ordinals: [String]? = nil,
        in context: ModelContext
    ) -> [EntityListItem] {
        context.insert(list)
        let items: [EntityListItem] = zip(uris, ordinals ?? uris.map { _ in "0" }).map { uri, ordinal in
            .init(
                _id: "\(list._id)-\(uri)",
                uri: uri,
                ordinal: ordinal,
                created: .init(timeIntervalSince1970: 0),
                itemType: list.type
            )
        }
        items.forEach(context.insert)
        list.elements.append(contentsOf: items)
        return items
    }

    @Test
    func `keeps my lists and my friends', and leaves a stranger's out`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let lea: User = Fixture.user(id: "lea", username: "lea", relation: .friend)
        let items: [EntityListItem] = [
            Self.insert(list: .mock(id: "mine", creatorId: "me"), holding: ["wd:Q1"], in: context),
            Self.insert(list: .mock(id: "lea", creatorId: "lea"), holding: ["wd:Q1"], in: context),
            Self.insert(list: .mock(id: "stranger", creatorId: "stranger"), holding: ["wd:Q1"], in: context)
        ].flatMap(\.self)

        let entries: BookListEntries = .init(items: items, myUserId: "me", friends: [lea])

        #expect(Set(entries.entries.map(\.list._id)) == ["mine", "lea"])
        let mine: BookListEntry = try #require(entries.entries.first { $0.list._id == "mine" })
        let leas: BookListEntry = try #require(entries.entries.first { $0.list._id == "lea" })
        #expect(mine.owner == nil)
        #expect(leas.owner?._id == "lea")
    }

    @Test
    func `leaves a list of authors out`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let items: [EntityListItem] = Self.insert(
            list: .mock(id: "authors", type: .author, creatorId: "me"),
            holding: ["wd:Q1"],
            in: context
        )

        let entries: BookListEntries = .init(items: items, myUserId: "me", friends: [])

        #expect(entries.isEmpty)
    }

    @Test
    func `shows a list holding two works of a recueil once, on the first in list order`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let items: [EntityListItem] = Self.insert(
            list: .mock(id: "recueil", creatorId: "me"),
            holding: ["wd:Q2", "wd:Q1"],
            ordinals: ["3", "1"],
            in: context
        )

        let entries: BookListEntries = .init(items: items, myUserId: "me", friends: [])

        #expect(entries.entries.map(\.list._id) == ["recueil"])
        #expect(entries.entries.first?.focusURI == "wd:Q1")
    }

    @Test
    func `orders mine and my friends' together, the most recently changed first`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let lea: User = Fixture.user(id: "lea", username: "lea", relation: .friend)
        let items: [EntityListItem] = [
            Self.insert(
                list: .mock(id: "mine-old", created: .init(timeIntervalSince1970: 100), creatorId: "me"),
                holding: ["wd:Q1"],
                in: context
            ),
            Self.insert(
                list: .mock(id: "lea-new", updated: .init(timeIntervalSince1970: 400), creatorId: "lea"),
                holding: ["wd:Q1"],
                in: context
            ),
            Self.insert(
                list: .mock(id: "mine-new", updated: .init(timeIntervalSince1970: 300), creatorId: "me"),
                holding: ["wd:Q1"],
                in: context
            ),
            Self.insert(
                list: .mock(id: "lea-old", created: .init(timeIntervalSince1970: 200), creatorId: "lea"),
                holding: ["wd:Q1"],
                in: context
            )
        ].flatMap(\.self)

        let entries: BookListEntries = .init(items: items, myUserId: "me", friends: [lea])

        #expect(entries.entries.map(\.list._id) == ["lea-new", "mine-new", "lea-old", "mine-old"])
    }

    @Test
    func `drops an element once it is deleted`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let kept: [EntityListItem] = Self.insert(list: .mock(id: "kept", creatorId: "me"), holding: ["wd:Q1"], in: context)
        let removed: [EntityListItem] = Self.insert(list: .mock(id: "removed", creatorId: "me"), holding: ["wd:Q1"], in: context)
        try context.save()

        removed.forEach(context.delete)
        try context.save()

        let entries: BookListEntries = .init(items: kept + removed, myUserId: "me", friends: [])

        #expect(entries.entries.map(\.list._id) == ["kept"])
    }
}
