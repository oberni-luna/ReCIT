//
//  NetworkGraphInputStoreTests.swift
//  ReCIT_iOSTests
//
//  The graph's snapshot, taken from the store's readers and my groups: my friends and the readers
//  waiting on me, never a request I sent nor a stranger; my groups and invitations, never a
//  request to join; who invited me, and the requests waiting on me as an admin (PRD 0019, Q4,
//  Q5, Q9, Q22).
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("NetworkGraphInput from the store")
struct NetworkGraphInputStoreTests {

    private func user(
        _ id: String,
        _ relation: UserRelation,
        picture: String? = nil
    ) -> User {
        let user: User = .init(
            _id: id,
            _rev: "",
            username: id.capitalized,
            email: nil,
            position: nil,
            avatarURLValue: picture,
            itemCount: 0,
            created: 1_600_000_000_000
        )
        user.relation = relation
        return user
    }

    private func group(
        _ id: String,
        admins: [String] = ["someone"],
        members: [String] = [],
        invited: [(String, String?)] = [],
        requested: [String] = []
    ) -> ReaderGroup {
        func list(_ ids: [String]) -> [GroupMembership] {
            ids.map { .init(user: $0, invitor: nil, timestamp: 0) }
        }
        return .init(
            id: id,
            name: id.capitalized,
            slug: nil,
            description: "",
            pictureURL: nil,
            searchable: true,
            open: false,
            admins: list(admins),
            members: list(members),
            invited: invited.map { .init(user: $0.0, invitor: $0.1, timestamp: 0) },
            declined: [],
            requested: list(requested)
        )
    }

    @Test("Friends and requesters only; me, strangers and my own requests left out")
    func readers() {
        let me: User = user("me", .none, picture: "https://inventaire.io/img/users/me")
        let users: [User] = [
            me,
            user("lea", .friend),
            user("ariane", .requestReceived),
            user("sent", .requestSent),
            user("stranger", .none)
        ]
        let input: NetworkGraphInput = .init(
            me: me,
            myUserId: "me",
            users: users,
            groups: .init([], me: "me")
        )

        #expect(input.me == .init(id: "me", username: "Me", pictureURL: "https://inventaire.io/img/users/me", created: 1_600_000_000_000))
        #expect(input.friends.map(\.id) == ["lea"])
        #expect(input.requesters.map(\.id) == ["ariane"])
    }

    @Test("Before my row arrives, my id comes from the groups' memory")
    func meNotStoredYet() {
        let input: NetworkGraphInput = .init(
            me: nil,
            myUserId: "me",
            users: [user("lea", .friend)],
            groups: .init([], me: "me")
        )

        #expect(input.me.id == "me")
        #expect(input.friends.map(\.id) == ["lea"])
    }

    @Test("My groups and invitations, with my role; a request to join is not drawn")
    func groups() throws {
        let groups: MyGroups = .init(
            [
                group("club", admins: ["me"], members: ["lea"], requested: ["x", "y"]),
                group("bd", members: ["me", "lea"]),
                group("l11", members: ["camille"], invited: [("me", "camille")]),
                group("asked", requested: ["me"])
            ],
            me: "me"
        )
        let input: NetworkGraphInput = .init(
            me: user("me", .none),
            myUserId: "me",
            users: [user("camille", .friend), user("lea", .friend)],
            groups: groups
        )
        let byId: [String: NetworkGraphGroup] = Dictionary(uniqueKeysWithValues: input.groups.map { ($0.id, $0) })

        #expect(Set(byId.keys) == ["club", "bd", "l11"])

        let club: NetworkGraphGroup = try #require(byId["club"])
        #expect(club.role == .admin)
        #expect(club.memberIds == ["me", "lea"])
        #expect(club.memberCount == 2)
        #expect(club.pendingCount == 2)

        let bd: NetworkGraphGroup = try #require(byId["bd"])
        #expect(bd.role == .member)
        #expect(bd.pendingCount == 0)

        let l11: NetworkGraphGroup = try #require(byId["l11"])
        #expect(l11.role == .invited)
        #expect(l11.invitorUsername == "Camille")
        #expect(l11.memberIds == ["someone", "camille"])
    }

    @Test("An invitation from someone the store does not know names nobody")
    func unknownInvitor() throws {
        let input: NetworkGraphInput = .init(
            me: user("me", .none),
            myUserId: "me",
            users: [],
            groups: .init([group("l11", invited: [("me", "ghost")])], me: "me")
        )

        #expect(try #require(input.groups.first).invitorUsername == nil)
    }
}
