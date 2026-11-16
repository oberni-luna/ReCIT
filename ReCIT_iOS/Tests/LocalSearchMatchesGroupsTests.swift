//
//  LocalSearchMatchesGroupsTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct LocalSearchMatchesGroupsTests {
    private func group(
        _ id: String,
        name: String,
        admins: [String] = ["admin"],
        members: [String] = [],
        invited: [String] = [],
        requested: [String] = []
    ) -> ReaderGroup {
        func memberships(_ ids: [String]) -> [GroupMembership] {
            ids.map { .init(user: $0, invitor: nil, timestamp: 0) }
        }
        return .init(
            id: id,
            name: name,
            slug: nil,
            description: "",
            pictureURL: nil,
            searchable: true,
            open: false,
            admins: memberships(admins),
            members: memberships(members),
            invited: memberships(invited),
            declined: [],
            requested: memberships(requested)
        )
    }

    @Test
    func `keeps the groups I am a member or an admin of, never an invitation or a request`() {
        let groups: [ReaderGroup] = [
            group("member", name: "Belles lettres", members: ["me"]),
            group("admin", name: "Club Bel-Air", admins: ["me"]),
            group("invited", name: "Bellevue", invited: ["me"]),
            group("requested", name: "Belleville", requested: ["me"]),
            group("unknown", name: "Bel ami")
        ]

        let matches: LocalSearchMatches<ReaderGroup> = .groups(in: MyGroups(groups, me: "me"), matching: "bel")

        #expect(matches.items.map(\.id) == ["member", "admin"])
        #expect(matches.totalCount == 2)
    }

    @Test
    func `matches the name whatever its case and accents, and only the name`() {
        let groups: [ReaderGroup] = [
            group("accent", name: "Lecteurs de l'Été", members: ["me"]),
            group("other", name: "Polars", members: ["me"])
        ]

        let matches: LocalSearchMatches<ReaderGroup> = .groups(in: MyGroups(groups, me: "me"), matching: "ete")

        #expect(matches.items.map(\.id) == ["accent"])
    }

    @Test
    func `shows three of four matching groups by name and is capped`() {
        let groups: [ReaderGroup] = [
            group("d", name: "Club D", members: ["me"]),
            group("a", name: "Club A", members: ["me"]),
            group("c", name: "Club C", admins: ["me"]),
            group("b", name: "Club B", members: ["me"])
        ]

        let matches: LocalSearchMatches<ReaderGroup> = .groups(in: MyGroups(groups, me: "me"), matching: "club")

        #expect(matches.items.map(\.id) == ["a", "b", "c"])
        #expect(matches.totalCount == 4)
        #expect(matches.isCapped)
    }

    @Test
    func `shows exactly three matching groups without being capped`() {
        let groups: [ReaderGroup] = [
            group("a", name: "Club A", members: ["me"]),
            group("b", name: "Club B", members: ["me"]),
            group("c", name: "Club C", members: ["me"])
        ]

        let matches: LocalSearchMatches<ReaderGroup> = .groups(in: MyGroups(groups, me: "me"), matching: "club")

        #expect(matches.items.count == 3)
        #expect(!matches.isCapped)
    }

    @Test
    func `matches no group for a blank query or without a signed-in reader`() {
        let groups: [ReaderGroup] = [group("a", name: "Club", members: ["me"])]

        let blank: LocalSearchMatches<ReaderGroup> = .groups(in: MyGroups(groups, me: "me"), matching: "")
        let nobody: LocalSearchMatches<ReaderGroup> = .groups(in: MyGroups(groups, me: nil), matching: "club")

        #expect(blank.items.isEmpty)
        #expect(nobody.items.isEmpty)
    }
}
