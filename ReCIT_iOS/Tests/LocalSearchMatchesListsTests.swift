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
    private let context: ModelContext
    private let lea: User = Fixture.user(id: "lea", username: "lea", relation: .friend)

    init() throws {
        context = try TestStore.makeContext()
        context.insert(lea)
    }

    private func stored(_ lists: [EntityList]) -> [EntityList] {
        lists.forEach(context.insert)
        return lists
    }

    @Test
    func `shows mine by name, then my friends', each friend's list with its owner`() {
        let lists: [EntityList] = stored([
            .mock(id: "lea-bel", name: "Belles histoires", creatorId: "lea"),
            .mock(id: "mine-z", name: "Zut, belle lecture", creatorId: "me"),
            .mock(id: "mine-a", name: "À la belle étoile", creatorId: "me")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            users: [lea],
            matching: "bel"
        )

        #expect(matches.items.map(\.list._id) == ["mine-a", "mine-z", "lea-bel"])
        #expect(matches.items.map(\.owner?._id) == [nil, nil, "lea"])
    }

    @Test
    func `matches every type of list, on its name only`() {
        let lists: [EntityList] = stored([
            .mock(id: "authors", name: "Belles plumes", type: .author, creatorId: "me"),
            .mock(id: "described", name: "Polars", explanation: "De bels polars", creatorId: "me")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            users: [],
            matching: "bel"
        )

        #expect(matches.items.map(\.list._id) == ["authors"])
    }

    @Test
    func `leaves out the list of a reader who is not my friend`() {
        let invited: User = Fixture.user(id: "invited", username: "invited", relation: .requestSent)
        context.insert(invited)
        let lists: [EntityList] = stored([
            .mock(id: "stranger", name: "Belles", creatorId: "stranger"),
            .mock(id: "invited", name: "Belles aussi", creatorId: "invited")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            users: [lea, invited],
            matching: "bel"
        )

        #expect(matches.items.isEmpty)
    }

    @Test
    func `shows three of four matching lists and is capped`() {
        let lists: [EntityList] = stored([
            .mock(id: "a", name: "Bel A", creatorId: "me"),
            .mock(id: "b", name: "Bel B", creatorId: "me"),
            .mock(id: "c", name: "Bel C", creatorId: "me"),
            .mock(id: "lea", name: "Bel D", creatorId: "lea")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            users: [lea],
            matching: "bel"
        )

        #expect(matches.items.map(\.list._id) == ["a", "b", "c"])
        #expect(matches.totalCount == 4)
        #expect(matches.isCapped)
    }

    @Test
    func `shows exactly three matching lists without being capped`() {
        let lists: [EntityList] = stored([
            .mock(id: "a", name: "Bel A", creatorId: "me"),
            .mock(id: "b", name: "Bel B", creatorId: "me"),
            .mock(id: "lea", name: "Bel C", creatorId: "lea")
        ])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            users: [lea],
            matching: "bel"
        )

        #expect(matches.items.count == 3)
        #expect(!matches.isCapped)
    }

    @Test
    func `matches no list for a blank query`() {
        let lists: [EntityList] = stored([.mock(id: "a", name: "Bel", creatorId: "me")])

        let matches: LocalSearchMatches<ListSearchMatch> = .lists(
            lists,
            myUserId: "me",
            users: [],
            matching: "  "
        )

        #expect(matches.items.isEmpty)
        #expect(matches.totalCount == 0)
    }
}
