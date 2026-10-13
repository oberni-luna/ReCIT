//
//  NetworkGraphAccessibilityTests.swift
//  ReCIT_iOSTests
//
//  What VoiceOver says of the Réseau graph (PRD 0019, Q44, issue 0110): a label for every node,
//  « Vous » the only heading, each node's actions, and the whole label of each kind of node —
//  read from the app's catalogue in French and in English, as shipped. The reading order itself
//  is `NetworkGraph`'s, tested in `NetworkGraphTests`.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite struct NetworkGraphAccessibilityTests {

    private let r1: NetworkGraph = .init(NetworkGraphFixture.r1)

    private static func bundle(_ language: String) throws -> Bundle {
        let url: URL = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        return try #require(Bundle(url: url))
    }

    private static let french: Locale = .init(identifier: "fr_FR")
    private static let english: Locale = .init(identifier: "en_US")

    private func french() throws -> NetworkGraphAccessibility {
        .init(r1, bundle: try Self.bundle("fr"), locale: Self.french)
    }

    private func english() throws -> NetworkGraphAccessibility {
        .init(r1, bundle: try Self.bundle("en"), locale: Self.english)
    }

    // MARK: - Every node

    @Test("Every node is described", arguments: [
        NetworkGraphFixture.r1,
        NetworkGraphFixture.r3,
        NetworkGraphFixture.stress
    ])
    func everyNodeIsDescribed(input: NetworkGraphInput) {
        let graph: NetworkGraph = .init(input)
        let accessibility: NetworkGraphAccessibility = .init(graph)

        for node in graph.nodes {
            #expect(accessibility[node]?.label.isEmpty == false)
        }
    }

    @Test func onlyMeIsAHeading() {
        let accessibility: NetworkGraphAccessibility = .init(r1)

        #expect(r1.nodes.filter { accessibility[$0]?.isHeader == true } == [.me])
    }

    @Test func eachNodeCarriesItsActions() {
        let accessibility: NetworkGraphAccessibility = .init(r1)

        for node in r1.nodes {
            #expect(accessibility[node]?.actions == r1.actions(for: node))
        }
    }

    @Test func nothingIsDescribedBeforeTheGraph() {
        #expect(NetworkGraphAccessibility()[.me] == nil)
    }

    // MARK: - Labels

    @Test func meIsVous() throws {
        #expect(try french()[.me]?.label == "Vous")
        #expect(try english()[.me]?.label == "You")
    }

    /// The Club: my role, the requests waiting on me as its admin, its members, then my friends.
    @Test func aGroupIAdministerSaysItsRequestsAndNamesItsFriends() throws {
        #expect(
            try french()[.group("club")]?.label
                == "Club de Belleville, Admin, 2 demandes à examiner, 12 membres, dont 4 de vos amis\u{202F}: Camille, Inès, Léa et Rémi."
        )
        #expect(
            try english()[.group("club")]?.label
                == "Club de Belleville, Admin, 2 requests to review, 12 members, including 4 of your friends: Camille, Inès, Léa, and Rémi."
        )
    }

    @Test func aGroupIBelongToSaysNoRole() throws {
        #expect(
            try french()[.group("bd")]?.label
                == "BD & romans graphiques, 48 membres, dont 3 de vos amis\u{202F}: Hugo, Rémi et Sami."
        )
    }

    @Test func anInvitationSaysWhoSentIt() throws {
        #expect(
            try french()[.group("l11")]?.label
                == "Lecteurs du 11e, Invitation de Camille, 31 membres, dont 2 de vos amis\u{202F}: Camille et Nora."
        )
        #expect(
            try english()[.group("l11")]?.label
                == "Lecteurs du 11e, Invited by Camille, 31 members, including 2 of your friends: Camille and Nora."
        )
    }

    @Test func anInvitationFromNobodyKnownSaysItWasReceived() throws {
        let graph: NetworkGraph = .init(
            .init(
                me: .init(id: "me", username: "me"),
                friends: [],
                requesters: [],
                groups: [.init(id: "l11", name: "Lecteurs du 11e", role: .invited, memberIds: [], memberCount: 31)]
            )
        )
        let accessibility: NetworkGraphAccessibility = .init(graph, bundle: try Self.bundle("fr"), locale: Self.french)

        #expect(accessibility[.group("l11")]?.label == "Lecteurs du 11e, Invitation reçue, 31 membres.")
    }

    /// Camille's invitation to the Lecteurs du 11e is not a group in common (Q27 bis).
    @Test func aFriendNamesTheGroupsWeShare() throws {
        #expect(try french()[.reader("camille")]?.label == "Camille, 1 groupe en commun\u{202F}: Club de Belleville.")
        #expect(
            try english()[.reader("remi")]?.label
                == "Rémi, 2 groups in common: Club de Belleville and BD & romans graphiques."
        )
    }

    @Test func aFriendInNoGroupIsTheirName() throws {
        #expect(try french()[.reader("paul")]?.label == "Paul")
    }

    @Test func aRequestSaysItWasReceived() throws {
        #expect(try french()[.reader("ariane")]?.label == "Ariane, Invitation reçue")
        #expect(try english()[.reader("ariane")]?.label == "Ariane, Invitation received")
    }
}
