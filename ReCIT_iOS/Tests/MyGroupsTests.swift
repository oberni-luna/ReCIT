//
//  MyGroupsTests.swift
//  ReCIT_iOSTests
//
//  The Groupes segment's sections and the Réseau badge, from values alone: where I stand in each
//  group decides its section, the name its place, and the requests to review only count where I
//  am an admin.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("MyGroups")
struct MyGroupsTests {

    private func group(
        _ id: String,
        name: String,
        admins: [String] = ["admin"],
        members: [String] = [],
        invited: [String] = [],
        declined: [String] = [],
        requested: [String] = []
    ) -> ReaderGroup {
        func list(_ ids: [String]) -> [GroupMembership] {
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
            admins: list(admins),
            members: list(members),
            invited: list(invited),
            declined: list(declined),
            requested: list(requested)
        )
    }

    @Test("Each group goes to the section of my role, by name")
    func sections() {
        let groups: MyGroups = .init(
            [
                group("b", name: "Polars", members: ["me"]),
                group("a", name: "club", admins: ["me"]),
                group("c", name: "Lecteurs du 11e", invited: ["me"]),
                group("d", name: "Voisins", requested: ["me"]),
                group("e", name: "Déclinés", declined: ["me"]),
                group("f", name: "Inconnus")
            ],
            me: "me"
        )

        #expect(groups.mine.map(\.id) == ["a", "b"])
        #expect(groups.invitations.map(\.id) == ["c"])
        #expect(groups.sentRequests.map(\.id) == ["d"])
        #expect(groups.isEmpty == false)
    }

    @Test("The requests to review count only in the groups I administer")
    func pending() {
        let groups: MyGroups = .init(
            [
                group("a", name: "A", admins: ["me"], requested: ["r1", "r2"]),
                group("b", name: "B", members: ["me"], requested: ["r3"]),
                group("c", name: "C", invited: ["me"])
            ],
            me: "me"
        )

        #expect(groups.requestsToReview == 2)
        #expect(groups.pendingCount == 3)
    }

    @Test("Without a signed-in reader, nothing is mine")
    func nobody() {
        let groups: MyGroups = .init([group("a", name: "A", admins: ["me"])], me: nil)

        #expect(groups.isEmpty)
        #expect(groups.pendingCount == 0)
    }

    @Test("Two groups of the same name keep one order")
    func sameName() {
        let groups: MyGroups = .init(
            [group("z", name: "Club", members: ["me"]), group("a", name: "Club", members: ["me"])],
            me: "me"
        )

        #expect(groups.mine.map(\.id) == ["a", "z"])
    }
}
