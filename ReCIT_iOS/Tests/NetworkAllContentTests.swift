//
//  NetworkAllContentTests.swift
//  ReCIT_iOSTests
//
//  « Tout » shows its empty state E1 when the graph would have nothing to draw around « Vous »:
//  no friend, no friend request received, no group I belong to or am invited into. What I sent —
//  a friend request, a request to join — is never drawn, so it leaves the network empty
//  (PRD 0019, Q4, Q5, Q39).
//

import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("NetworkAllContent")
struct NetworkAllContentTests {

    private func group(
        _ id: String,
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
            name: id,
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

    private func content(
        relations: [UserRelation] = [],
        groups: [ReaderGroup] = []
    ) -> NetworkAllContent {
        .init(relations: relations, groups: .init(groups, me: "me"))
    }

    @Test("Nobody and nothing: the empty state")
    func nothing() {
        #expect(content() == .empty)
    }

    @Test("Readers met elsewhere are not my network", arguments: [[UserRelation.none], [.none, .none]])
    func strangers(relations: [UserRelation]) {
        #expect(content(relations: relations) == .empty)
    }

    @Test("A friend request I sent is not drawn")
    func sentFriendRequest() {
        #expect(content(relations: [.requestSent]) == .empty)
    }

    @Test("A friend, or a friend request waiting on me, is drawn", arguments: [UserRelation.friend, .requestReceived])
    func reader(relation: UserRelation) {
        #expect(content(relations: [.none, relation]) == .graph)
    }

    @Test("A group I administer, belong to or am invited into is drawn")
    func groupsDrawn() {
        #expect(content(groups: [group("a", admins: ["me"])]) == .graph)
        #expect(content(groups: [group("m", members: ["me"])]) == .graph)
        #expect(content(groups: [group("i", invited: ["me"])]) == .graph)
    }

    @Test("A request to join, a declined invitation, a group without me: not drawn")
    func groupsNotDrawn() {
        #expect(content(groups: [group("r", requested: ["me"])]) == .empty)
        #expect(content(groups: [group("d", declined: ["me"])]) == .empty)
        #expect(content(groups: [group("x", members: ["someone"])]) == .empty)
    }
}
