//
//  NetworkGraphRenderingRulesTests.swift
//  ReCIT_iOSTests
//
//  The small rules the Réseau graph is drawn by: what a group card's second line says (Q9), when
//  the nodes slide (Q17, Q23), and how positions interpolate so that a node that arrives slides
//  out of « Vous » (PRD 0019); since issue 0109, the two sets of line styles (Q32), the boxes of
//  the overview (R3), and what the status pill says (Q10, Q40, Q41).
//

import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Network graph rendering rules")
struct NetworkGraphRenderingRulesTests {

    // MARK: - Card detail

    @Test("A card says « Admin · N membres », « N membres » or « Invitation de X »")
    func cardDetail() {
        #expect(NetworkGroupCardDetail(.init(id: "a", name: "A", role: .admin, memberIds: [], memberCount: 12)) == .admin(memberCount: 12))
        #expect(NetworkGroupCardDetail(.init(id: "m", name: "M", role: .member, memberIds: [], memberCount: 48)) == .members(count: 48))
        #expect(NetworkGroupCardDetail(.init(id: "i", name: "I", role: .invited, memberIds: [], invitorUsername: "Camille")) == .invitation(from: "Camille"))
    }

    @Test("An invitation from an unknown reader falls back on the number of members")
    func cardDetailWithoutInvitor() {
        #expect(NetworkGroupCardDetail(.init(id: "i", name: "I", role: .invited, memberIds: [], memberCount: 31)) == .members(count: 31))
        #expect(NetworkGroupCardDetail(.init(id: "i", name: "I", role: .invited, memberIds: [], memberCount: 31, invitorUsername: "")) == .members(count: 31))
    }

    @Test("The words come from the Groupes list's own keys")
    func cardDetailText() {
        #expect(
            NetworkGroupCardDetail.admin(memberCount: 12).text
                == String(localized: "groups.role.admin") + " · " + String(localized: "groups.members_count \(12)")
        )
        #expect(NetworkGroupCardDetail.members(count: 1).text == String(localized: "groups.members_count \(1)"))
        #expect(NetworkGroupCardDetail.invitation(from: "Camille").text == String(localized: "groups.invited_by \("Camille")"))
        #expect(NetworkGroupCardDetail.invitation(from: "Camille").text.contains("Camille"))
    }

    // MARK: - Motion

    @Test("Opening shows the graph in place; a change slides it, unless Reduce Motion is on")
    func motion() {
        #expect(NetworkGraphMotion.animation(isFirstPlacement: true, reduceMotion: false) == nil)
        #expect(NetworkGraphMotion.animation(isFirstPlacement: true, reduceMotion: true) == nil)
        #expect(NetworkGraphMotion.animation(isFirstPlacement: false, reduceMotion: true) == nil)
        #expect(NetworkGraphMotion.animation(isFirstPlacement: false, reduceMotion: false) != nil)
    }

    // MARK: - Positions

    @Test("Halfway between two placements, every node is halfway; one that arrives starts on « Vous »")
    func interpolation() {
        let from: NetworkGraphPositions = .init([
            .me: .zero,
            .reader("lea"): .init(x: 100, y: -50),
            .reader("paul"): .init(x: -40, y: 20)
        ])
        let to: NetworkGraphPositions = .init([
            .me: .zero,
            .reader("lea"): .init(x: 140, y: -10),
            .reader("zoe"): .init(x: 60, y: 80)
        ])

        let halfway: NetworkGraphPositions = from + (to - from).scaled(by: 0.5)

        #expect(halfway[.reader("lea")] == .init(x: 120, y: -30))
        #expect(halfway[.reader("zoe")] == .init(x: 30, y: 40))
        #expect(halfway[.me] == .zero)
        #expect(from + (to - from) == to + .init([.reader("paul"): .zero]))
    }

    @Test("Positions add, subtract and measure like vectors")
    func vectorArithmetic() {
        let positions: NetworkGraphPositions = .init([.me: .init(x: 3, y: 4)])

        #expect(positions.magnitudeSquared == 25)
        #expect(positions - positions == .init([.me: .zero]))
        #expect(positions + .zero == positions)
        #expect(NetworkGraphPositions.zero.magnitudeSquared == 0)
    }

    // MARK: - Line styles

    @Test("In full, R1's lines; in the overview, R3's")
    func lineStyles() {
        let fullToGroup: NetworkEdgeStyle = .init(.meToGroup, level: .full)
        #expect(fullToGroup.lineWidth == 1.5)
        #expect(fullToGroup.opacity == 0.6)
        #expect(NetworkEdgeStyle(.friendToGroup, level: .full) == fullToGroup)

        let overviewToGroup: NetworkEdgeStyle = .init(.meToGroup, level: .overview)
        #expect(overviewToGroup.lineWidth == 2)
        #expect(overviewToGroup.opacity == 0.8)
        #expect(overviewToGroup.isDashed == false)
        let overviewInvitation: NetworkEdgeStyle = .init(.meToInvitation, level: .overview)
        #expect(overviewInvitation.lineWidth == 2)
        #expect(overviewInvitation.opacity == 0.8)
        #expect(overviewInvitation.isDashed)

        let overviewFriendToGroup: NetworkEdgeStyle = .init(.friendToGroup, level: .overview)
        #expect(overviewFriendToGroup.lineWidth == 1)
        #expect(overviewFriendToGroup.opacity == 0.3)

        // « Vous » ↔ a friend is the same light line at both levels (Q32 bis).
        #expect(NetworkEdgeStyle(.meToFriend, level: .overview) == NetworkEdgeStyle(.meToFriend, level: .full))
        #expect(NetworkEdgeStyle(.meToFriend, level: .full).opacity == 0.3)
        #expect(NetworkEdgeStyle(.meToRequester, level: .overview).isDashed)
    }

    @Test("Lit, a line is 2.5 pt at full strength, dashed still; dimmed, it keeps its width at 12 %")
    func litAndDimmedLines() {
        let invitation: NetworkEdgeStyle = .init(.meToInvitation, level: .overview)
        #expect(invitation.lit.lineWidth == 2.5)
        #expect(invitation.lit.opacity == 1)
        #expect(invitation.lit.isDashed)
        #expect(invitation.dimmed.lineWidth == 2)
        #expect(invitation.dimmed.opacity == 0.12)
    }

    // MARK: - Overview boxes

    @Test("In the overview: « Vous » at 70 %, readers as 24 pt dots, groups as their tile, anchored at the tile")
    func overviewBoxes() {
        let graph: NetworkGraph = .init(NetworkGraphFixture.r1)
        let me: NetworkNodeBox = .init(size: .init(width: 72, height: 84), anchor: .init(x: 36, y: 36))
        let boxes: [NetworkNodeID: NetworkNodeBox] = NetworkOverviewBoxes.boxes(
            graph: graph,
            fullBoxes: [.me: me],
            tileSizes: [.group("club"): .init(width: 110, height: 72)]
        )

        #expect(boxes[.me] == me.scaled(by: 0.7))
        #expect(boxes[.reader("ines")] == .init(centred: .init(width: 24, height: 24)))
        #expect(boxes[.reader("ariane")] == .init(centred: .init(width: 24, height: 24)))
        #expect(boxes[.group("club")] == .init(size: .init(width: 110, height: 72), anchor: .init(x: 55, y: 26)))
        // Not measured yet: the bare tile.
        #expect(boxes[.group("bd")] == .init(centred: .init(width: 52, height: 52)))
    }

    // MARK: - Status pill

    @Test("The counter once relations and groups have both answered; R3 counts 42 · 6")
    func statusCounter() {
        let counter: NetworkGraphCounter = NetworkGraph(NetworkGraphFixture.r3).counter
        #expect(NetworkGraphStatus(counter: counter, community: .synced, groups: .synced) == .counter(.init(friends: 42, groups: 6)))
    }

    @Test("« Synchronisation… » while either is on its way, « Réessayer » once neither is and one failed", arguments: [
        (SyncStatusStore.Phase.pending, SyncStatusStore.Phase.pending, NetworkGraphStatus.syncing),
        (.syncing, .pending, .syncing),
        (.synced, .syncing, .syncing),
        (.failed, .syncing, .syncing),
        (.failed, .synced, .retry),
        (.synced, .failed, .retry),
        (.failed, .failed, .retry),
        (.failed, .pending, .retry)
    ])
    func statusBeforeTheFirstSync(
        community: SyncStatusStore.Phase,
        groups: SyncStatusStore.Phase,
        expected: NetworkGraphStatus
    ) {
        #expect(NetworkGraphStatus(counter: .init(friends: 1, groups: 1), community: community, groups: groups) == expected)
    }

    @Test("The status follows the store: syncing, then the counter; a failed first launch, then « Réessayer »")
    func statusFollowsTheStore() throws {
        let defaults: UserDefaults = try #require(UserDefaults(suiteName: "network-status-\(UUID().uuidString)"))
        let store: SyncStatusStore = .init(defaults: defaults)
        let counter: NetworkGraphCounter = .init(friends: 42, groups: 6)
        let status: () -> NetworkGraphStatus = {
            .init(counter: counter, community: store.phase(.community), groups: store.phase(.groups))
        }

        store.markStarted(.community)
        store.markStarted(.groups)
        #expect(status() == .syncing)
        store.markFailed(.community)
        #expect(status() == .syncing)
        store.markFailed(.groups)
        #expect(status() == .retry)

        // « Réessayer » runs the sync again.
        store.markStarted(.community)
        store.markStarted(.groups)
        #expect(status() == .syncing)
        store.markCompleted(.community)
        store.markCompleted(.groups)
        #expect(status() == .counter(counter))

        // A later failure says nothing (Q41).
        store.markFailed(.groups)
        #expect(status() == .counter(counter))
    }
}
