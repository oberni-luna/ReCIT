//
//  NetworkGraphTests.swift
//  ReCIT_iOSTests
//
//  What « Tout » draws, from values alone (PRD 0019, module 4): the nodes and the lines of R1′,
//  one node for a friend in two groups, nobody who is not my friend, the isolated friend and the
//  requester tied to me alone, the counter, the groups in common, what a touch lights, and the
//  order VoiceOver reads it all in.
//

import Testing
@testable import ReCIT_iOS

@Suite("NetworkGraph")
struct NetworkGraphTests {

    private let r1: NetworkGraph = .init(NetworkGraphFixture.r1)

    private func edge(
        _ from: NetworkNodeID,
        _ to: NetworkNodeID,
        _ kind: NetworkEdgeKind
    ) -> NetworkEdge {
        .init(from: from, to: to, kind: kind)
    }

    // MARK: - R1

    @Test("R1: « Vous », three groups in the order of the ring, nine readers by handle")
    func r1Nodes() {
        #expect(r1.me.id == "me")
        #expect(r1.groups.map(\.id) == ["club", "bd", "l11"])
        #expect(r1.readers.map(\.id) == ["ariane", "camille", "hugo", "ines", "lea", "nora", "paul", "remi", "sami"])
        #expect(r1.nodes.count == 13)
        #expect(r1.nodes.first == .me)
    }

    @Test("R1: the lines of the mock-up, and no other")
    func r1Edges() {
        let expected: Set<NetworkEdge> = [
            edge(.me, .group("club"), .meToGroup),
            edge(.me, .group("bd"), .meToGroup),
            edge(.me, .group("l11"), .meToInvitation),
            edge(.me, .reader("ariane"), .meToRequester),
            edge(.me, .reader("camille"), .meToFriend),
            edge(.me, .reader("hugo"), .meToFriend),
            edge(.me, .reader("ines"), .meToFriend),
            edge(.me, .reader("lea"), .meToFriend),
            edge(.me, .reader("nora"), .meToFriend),
            edge(.me, .reader("paul"), .meToFriend),
            edge(.me, .reader("remi"), .meToFriend),
            edge(.me, .reader("sami"), .meToFriend),
            edge(.reader("camille"), .group("club"), .friendToGroup),
            edge(.reader("ines"), .group("club"), .friendToGroup),
            edge(.reader("lea"), .group("club"), .friendToGroup),
            edge(.reader("remi"), .group("club"), .friendToGroup),
            edge(.reader("hugo"), .group("bd"), .friendToGroup),
            edge(.reader("remi"), .group("bd"), .friendToGroup),
            edge(.reader("sami"), .group("bd"), .friendToGroup),
            edge(.reader("camille"), .group("l11"), .friendToGroup),
            edge(.reader("nora"), .group("l11"), .friendToGroup)
        ]

        #expect(Set(r1.edges) == expected)
        #expect(r1.edges.count == expected.count)
    }

    @Test("R1: Paul, in none of my groups, is isolated; Ariane is a requester, tied to me by a dashed line")
    func r1IsolatedAndRequester() {
        #expect(r1.reader(id: "paul")?.isIsolated == true)
        #expect(r1.reader(id: "paul")?.state == .friend)
        #expect(r1.reader(id: "ariane")?.state == .requested)
        #expect(r1.reader(id: "ariane")?.isIsolated == true)
        #expect(r1.edges.filter { $0.touches(.reader("ariane")) }.map(\.kind) == [.meToRequester])
        #expect(NetworkEdgeKind.meToRequester.isDashed)

        let isolated: [String] = r1.readers.filter(\.isIsolated).map(\.id)
        #expect(isolated == ["ariane", "paul"])
    }

    @Test("A friend only in a group that invited me is joined to it, so not isolated")
    func invitationMemberIsNotIsolated() {
        #expect(r1.reader(id: "nora")?.isIsolated == false)
        #expect(r1.groupOffsets(of: "nora") == [2])
    }

    @Test("An invitation is dashed to « Vous »; a friend's line to it is not")
    func invitationLines() {
        let lines: [NetworkEdge] = r1.edges.filter { $0.touches(.group("l11")) }

        #expect(lines.filter(\.kind.isDashed) == [edge(.me, .group("l11"), .meToInvitation)])
        #expect(lines.filter { $0.kind == .friendToGroup }.count == 2)
    }

    // MARK: - One node per reader, friends only

    @Test("A friend in two groups is one node with two lines")
    func friendInTwoGroups() {
        #expect(r1.readers.filter { $0.id == "remi" }.count == 1)
        let lines: [NetworkEdge] = r1.edges.filter { $0.touches(.reader("remi")) && $0.kind == .friendToGroup }
        #expect(lines.map(\.to) == [.group("club"), .group("bd")])
    }

    @Test("A member of my groups who is not my friend is not drawn")
    func strangersAreNotDrawn() {
        let readerIds: Set<String> = Set(r1.readers.map(\.id))

        #expect(readerIds.contains("club-stranger-0") == false)
        #expect(r1.edges.contains { $0.touches(.reader("club-stranger-0")) } == false)
        // They still count in « N membres ».
        #expect(r1.group(id: "club")?.memberCount == 12)
    }

    @Test("A requester in one of my groups is still tied to me alone")
    func requesterInAGroup() {
        let input: NetworkGraphInput = .init(
            me: .init(id: "me", username: "me"),
            friends: [],
            requesters: [NetworkGraphFixture.reader("ariane", "Ariane")],
            groups: [.init(id: "g", name: "G", role: .member, memberIds: ["me", "ariane"])]
        )
        let graph: NetworkGraph = .init(input)

        #expect(graph.edges.filter { $0.touches(.reader("ariane")) }.map(\.kind) == [.meToRequester])
        #expect(graph.reader(id: "ariane")?.isIsolated == true)
    }

    @Test("A reader listed twice, or myself among my friends, is drawn once or not at all")
    func duplicates() {
        let input: NetworkGraphInput = .init(
            me: .init(id: "me", username: "me"),
            friends: [
                NetworkGraphFixture.reader("lea", "Léa"),
                NetworkGraphFixture.reader("lea", "Léa"),
                NetworkGraphFixture.reader("me", "me")
            ],
            requesters: [NetworkGraphFixture.reader("lea", "Léa")],
            groups: [
                .init(id: "g", name: "G", role: .member, memberIds: ["me", "lea", "lea"]),
                .init(id: "g", name: "G", role: .member, memberIds: ["me", "lea"])
            ]
        )
        let graph: NetworkGraph = .init(input)

        #expect(graph.readers.map(\.id) == ["lea"])
        #expect(graph.readers.first?.state == .friend)
        #expect(graph.groups.count == 1)
        #expect(graph.edges.count == 3)
    }

    // MARK: - Order of the ring

    @Test("Groups by role — admin, member, invitation — then by name, as Finder sorts it")
    func ringOrder() {
        let input: NetworkGraphInput = .init(
            me: .init(id: "me", username: "me"),
            friends: [],
            requesters: [],
            groups: [
                .init(id: "invited", name: "Aaa", role: .invited, memberIds: []),
                .init(id: "member10", name: "Club 10", role: .member, memberIds: []),
                .init(id: "member2", name: "club 2", role: .member, memberIds: []),
                .init(id: "admin", name: "Zèbre", role: .admin, memberIds: [])
            ]
        )

        #expect(NetworkGraph(input).groups.map(\.id) == ["admin", "member2", "member10", "invited"])
    }

    // MARK: - Counter

    @Test("The counter: accepted friends · groups I administer or belong to", arguments: [
        (NetworkGraphFixture.r1, 8, 2),
        (NetworkGraphFixture.r3, 42, 6),
        (NetworkGraphFixture.stress, 200, 27)
    ])
    func counter(input: NetworkGraphInput, friends: Int, groups: Int) {
        #expect(NetworkGraph(input).counter == .init(friends: friends, groups: groups))
    }

    // MARK: - Overview

    @Test("Overview of R3: only the friends without a group keep their line to « Vous »; every line is drawn in full")
    func overviewLinesOfR3() {
        let graph: NetworkGraph = .init(NetworkGraphFixture.r3)
        let toFriends: [NetworkEdge] = graph.edges.filter { $0.kind == .meToFriend }
        let kept: [NetworkEdge] = toFriends.filter { graph.isDrawn($0, at: .overview) }

        #expect(toFriends.count == 42)
        #expect(Set(kept.map(\.to)) == [.reader("sarah"), .reader("nathan"), .reader("mila"), .reader("clara")])
        #expect(graph.edges.filter { $0.kind != .meToFriend }.allSatisfy { graph.isDrawn($0, at: .overview) })
        #expect(graph.edges.allSatisfy { graph.isDrawn($0, at: .full) })
    }

    @Test("Overview of R1: the requester's dashed line and the isolated friend's line stay")
    func overviewLinesOfR1() {
        #expect(r1.isDrawn(edge(.me, .reader("ariane"), .meToRequester), at: .overview))
        #expect(r1.isDrawn(edge(.me, .reader("paul"), .meToFriend), at: .overview))
        #expect(r1.isDrawn(edge(.me, .reader("ines"), .meToFriend), at: .overview) == false)
        #expect(r1.isDrawn(edge(.me, .group("l11"), .meToInvitation), at: .overview))
        #expect(r1.isDrawn(edge(.reader("camille"), .group("l11"), .friendToGroup), at: .overview))
    }

    // MARK: - Neighbours

    @Test("A group's friends, by handle")
    func friendsOfAGroup() {
        #expect(r1.friends(in: "club").map(\.username) == ["Camille", "Inès", "Léa", "Rémi"])
        #expect(r1.friends(in: "l11").map(\.username) == ["Camille", "Nora"])
        #expect(r1.friends(in: "unknown").isEmpty)
    }

    @Test("Groups in common leave the invitations out; they are lit apart")
    func commonGroups() {
        #expect(r1.commonGroups(of: "camille").map(\.id) == ["club"])
        #expect(r1.invitedGroups(of: "camille").map(\.id) == ["l11"])
        #expect(r1.commonGroups(of: "remi").map(\.id) == ["club", "bd"])
        #expect(r1.commonGroups(of: "nora").isEmpty)
        #expect(r1.commonGroups(of: "paul").isEmpty)
        #expect(r1.commonGroups(of: "ariane").isEmpty)
    }

    @Test("Touching a group lights « Vous », the group, its friends and its five lines")
    func highlightGroup() throws {
        let highlight: NetworkGraphHighlight = try #require(r1.highlight(for: .group("club")))

        #expect(highlight.nodes == [.me, .group("club"), .reader("ines"), .reader("lea"), .reader("remi"), .reader("camille")])
        #expect(highlight.edges.count == 5)
        #expect(highlight.edges.allSatisfy { $0.touches(.group("club")) })
        #expect(highlight.contains(edge(.me, .reader("ines"), .meToFriend)) == false)
    }

    @Test("Touching a friend lights « Vous », the friend, their groups — the invitation too — and their lines")
    func highlightFriend() throws {
        let highlight: NetworkGraphHighlight = try #require(r1.highlight(for: .reader("camille")))

        #expect(highlight.nodes == [.me, .reader("camille"), .group("club"), .group("l11")])
        #expect(highlight.edges == [
            edge(.me, .reader("camille"), .meToFriend),
            edge(.reader("camille"), .group("club"), .friendToGroup),
            edge(.reader("camille"), .group("l11"), .friendToGroup)
        ])
    }

    @Test("Touching « Vous », or a node not drawn, lights nothing")
    func highlightNothing() {
        #expect(r1.highlight(for: .me) == nil)
        #expect(r1.highlight(for: .group("unknown")) == nil)
        #expect(r1.highlight(for: .reader("club-stranger-0")) == nil)
    }

    // MARK: - Reading order

    @Test("VoiceOver: « Vous », what waits on me, my groups, then each friend once")
    func readingOrder() {
        #expect(r1.readingOrder == [
            .me,
            .reader("ariane"),
            .group("l11"),
            .group("club"),
            .group("bd"),
            .reader("camille"),
            .reader("hugo"),
            .reader("ines"),
            .reader("lea"),
            .reader("nora"),
            .reader("paul"),
            .reader("remi"),
            .reader("sami")
        ])
    }

    @Test("Every node is read exactly once", arguments: [NetworkGraphFixture.r3, NetworkGraphFixture.stress])
    func readingOrderCoversEveryNode(input: NetworkGraphInput) {
        let graph: NetworkGraph = .init(input)

        #expect(graph.readingOrder.count == graph.nodes.count)
        #expect(Set(graph.readingOrder) == Set(graph.nodes))
    }

    // MARK: - Empty

    @Test("Nobody and nothing: only « Vous »")
    func empty() {
        let graph: NetworkGraph = .init(
            .init(me: .init(id: "me", username: "me"), friends: [], requesters: [], groups: [])
        )

        #expect(graph.isEmpty)
        #expect(graph.nodes == [.me])
        #expect(graph.edges.isEmpty)
        #expect(graph.counter == .init(friends: 0, groups: 0))
    }
}
