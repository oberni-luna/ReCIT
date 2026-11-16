//
//  LocalSearchMatchesListsTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct LocalSearchMatchesListsTests {
    private let lea: User = Fixture.user(id: "lea", username: "lea", relation: .friend)

    private func stored(_ lists: [EntityList]) throws -> [EntityList] {
        let context: ModelContext = try TestStore.makeContext()
        lists.forEach(context.insert)
        return lists
    }

    @Test
    func `shows mine by name, then my friends', each friend's list with its owner`() throws {
        let lists: [EntityList] = try stored([
            .mock(id: "lea-bel", name: "Belles histoires", creatorId: "lea"),
            .mock(id: "mine-z", name: "Zut, belle lecture", creatorId: "me"),
            .mock(id: "mine-a", name: "À la belle étoile", creatorId: "me")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            friends: [lea],
            matching: "bel"
        )

        #expect(matches.items.map(\.list._id) == ["mine-a", "mine-z", "lea-bel"])
        #expect(matches.items.map(\.owner?._id) == [nil, nil, "lea"])
    }

    @Test
    func `matches every type of list, on its name only`() throws {
        let lists: [EntityList] = try stored([
            .mock(id: "authors", name: "Belles plumes", type: .author, creatorId: "me"),
            .mock(id: "described", name: "Polars", explanation: "De bels polars", creatorId: "me")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            friends: [],
            matching: "bel"
        )

        #expect(matches.items.map(\.list._id) == ["authors"])
    }

    @Test
    func `leaves out a stranger's list`() throws {
        let lists: [EntityList] = try stored([.mock(id: "stranger", name: "Belles", creatorId: "stranger")])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            friends: [lea],
            matching: "bel"
        )

        #expect(matches.items.isEmpty)
    }

    @Test
    func `shows three of four matching lists and is capped`() throws {
        let lists: [EntityList] = try stored([
            .mock(id: "a", name: "Bel A", creatorId: "me"),
            .mock(id: "b", name: "Bel B", creatorId: "me"),
            .mock(id: "c", name: "Bel C", creatorId: "me"),
            .mock(id: "lea", name: "Bel D", creatorId: "lea")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            friends: [lea],
            matching: "bel"
        )

        #expect(matches.items.map(\.list._id) == ["a", "b", "c"])
        #expect(matches.totalCount == 4)
        #expect(matches.isCapped)
    }

    @Test
    func `shows exactly three matching lists without being capped`() throws {
        let lists: [EntityList] = try stored([
            .mock(id: "a", name: "Bel A", creatorId: "me"),
            .mock(id: "b", name: "Bel B", creatorId: "me"),
            .mock(id: "lea", name: "Bel C", creatorId: "lea")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            friends: [lea],
            matching: "bel"
        )

        #expect(matches.items.count == 3)
        #expect(!matches.isCapped)
    }

    @Test
    func `matches no list for a blank query`() throws {
        let lists: [EntityList] = try stored([.mock(id: "a", name: "Bel", creatorId: "me")])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            friends: [],
            matching: "  "
        )

        #expect(matches.items.isEmpty)
        #expect(matches.totalCount == 0)
    }
}
