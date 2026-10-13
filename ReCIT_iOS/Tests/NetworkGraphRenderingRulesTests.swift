//
//  NetworkGraphRenderingRulesTests.swift
//  ReCIT_iOSTests
//
//  The small rules the Réseau graph is drawn by: what a group card's second line says (Q9), when
//  the nodes slide (Q17, Q23), and how positions interpolate so that a node that arrives slides
//  out of « Vous » (PRD 0019).
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
}
