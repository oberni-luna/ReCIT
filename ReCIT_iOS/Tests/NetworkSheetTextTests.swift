//
//  NetworkSheetTextTests.swift
//  ReCIT_iOSTests
//
//  What the sheets of the Réseau graph say (PRD 0019, Q27, Q27 bis, Q29, Q29 bis): the names rule
//  for 0, 1, 4, 5 and 6 friends; a group's sentence, which stops at its members when no friend of
//  mine is in it; a friend's groups in common, which never count an invitation. The sentences are
//  read from the app's catalogue in French and in English, so the plural substitutions and the
//  narrow no-break space before the French colon are checked as they are shipped.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite struct NetworkSheetTextTests {

    private let r1: NetworkGraph = .init(NetworkGraphFixture.r1)

    private static func bundle(_ language: String) throws -> Bundle {
        let url: URL = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        return try #require(Bundle(url: url))
    }

    private static let french: Locale = .init(identifier: "fr_FR")
    private static let english: Locale = .init(identifier: "en_US")

    private func readers(_ count: Int) -> [NetworkGraphReader] {
        ["Inès", "Léa", "Rémi", "Camille", "Hugo", "Sami"].prefix(count).map { .init(id: $0, username: $0) }
    }

    private func group(role: NetworkGroupRole = .admin, members: Int = 12) -> NetworkGraphGroup {
        .init(id: "club", name: "Club de Belleville", role: role, memberIds: [], memberCount: members)
    }

    // MARK: - The names rule

    @Test(arguments: [
        (0, [String](), 0),
        (1, ["Inès"], 0),
        (4, ["Inès", "Léa", "Rémi", "Camille"], 0),
        (5, ["Inès", "Léa", "Rémi"], 2),
        (6, ["Inès", "Léa", "Rémi"], 3)
    ])
    func namesUpToFourThenThreeAndTheOthers(count: Int, named: [String], others: Int) {
        let list: NetworkNameList = .init(readers(count).map(\.username))

        #expect(list.names == named)
        #expect(list.others == others)
        #expect(list.count == count)
    }

    @Test func neverAndOneOther() {
        for count in 0...20 {
            #expect(NetworkNameList(Array(repeating: "x", count: count)).others != 1)
        }
    }

    // MARK: - A group's sheet

    @Test(arguments: [0, 1, 4, 5, 6])
    func atMostFiveAvatarsInTheOrderNamed(count: Int) {
        let summary: NetworkGroupSummary = .init(group: group(), friends: readers(count))

        #expect(summary.avatars.map(\.username) == Array(readers(count).map(\.username).prefix(5)))
        #expect(summary.friendCount == count)
        #expect(summary.namesFriends == (count > 0))
    }

    @Test func theClubOfR1NamesItsFourFriends() throws {
        let club: NetworkGraphGroup = try #require(r1.group(id: "club"))
        let summary: NetworkGroupSummary = .init(group: club, in: r1)

        #expect(summary.lead == .admin(memberCount: 12))
        #expect(summary.friendNames.names == ["Camille", "Inès", "Léa", "Rémi"])
        #expect(
            summary.sentence(bundle: try Self.bundle("fr"), locale: Self.french)
                == "Admin · 12 membres, dont 4 de vos amis\u{202F}: Camille, Inès, Léa et Rémi."
        )
    }

    @Test(arguments: [
        (0, "Admin · 12 membres."),
        (1, "Admin · 12 membres, dont 1 de vos amis\u{202F}: Inès."),
        (4, "Admin · 12 membres, dont 4 de vos amis\u{202F}: Inès, Léa, Rémi et Camille."),
        (5, "Admin · 12 membres, dont 5 de vos amis\u{202F}: Inès, Léa, Rémi et 2 autres."),
        (6, "Admin · 12 membres, dont 6 de vos amis\u{202F}: Inès, Léa, Rémi et 3 autres.")
    ])
    func theFrenchSentence(count: Int, expected: String) throws {
        let summary: NetworkGroupSummary = .init(group: group(), friends: readers(count))

        #expect(summary.sentence(bundle: try Self.bundle("fr"), locale: Self.french) == expected)
    }

    @Test(arguments: [
        (0, "Admin · 12 members."),
        (1, "Admin · 12 members, including 1 of your friends: Inès."),
        (6, "Admin · 12 members, including 6 of your friends: Inès, Léa, Rémi, and 3 others.")
    ])
    func theEnglishSentence(count: Int, expected: String) throws {
        let summary: NetworkGroupSummary = .init(group: group(), friends: readers(count))

        #expect(summary.sentence(bundle: try Self.bundle("en"), locale: Self.english) == expected)
    }

    /// A member's sheet says no role; an invitation's says its members, not who sent it.
    @Test func memberAndInvitationOpenOnTheMembers() throws {
        let french: Bundle = try Self.bundle("fr")
        let member: NetworkGroupSummary = .init(group: group(role: .member, members: 48), friends: [])
        let invitation: NetworkGroupSummary = .init(
            group: .init(id: "l11", name: "Lecteurs du 11e", role: .invited, memberIds: [], memberCount: 31, invitorUsername: "Camille"),
            friends: readers(1)
        )

        #expect(member.sentence(bundle: french, locale: Self.french) == "48 membres.")
        #expect(invitation.sentence(bundle: french, locale: Self.french) == "31 membres, dont 1 de vos amis\u{202F}: Inès.")
    }

    // MARK: - A friend's sheet

    /// Camille belongs to the Club and was the one who invited me into the Lecteurs du 11e: the
    /// invitation is not a group in common.
    @Test func groupsInCommonLeaveTheInvitationsOut() throws {
        let camille: NetworkReaderNode = try #require(r1.reader(id: "camille"))
        let summary: NetworkReaderSummary = .init(reader: camille, in: r1)

        #expect(r1.invitedGroups(of: "camille").map(\.id) == ["l11"])
        #expect(summary.commonGroupCount == 1)
        #expect(summary.commonGroupNames.names == ["Club de Belleville"])
        #expect(
            summary.commonGroupsText(bundle: try Self.bundle("fr"), locale: Self.french)
                == "1 groupe en commun\u{202F}: Club de Belleville."
        )
    }

    @Test func groupsInCommonCountedInTheirPlural() throws {
        let remi: NetworkReaderNode = try #require(r1.reader(id: "remi"))
        let summary: NetworkReaderSummary = .init(reader: remi, in: r1)

        #expect(
            summary.commonGroupsText(bundle: try Self.bundle("fr"), locale: Self.french)
                == "2 groupes en commun\u{202F}: Club de Belleville et BD & romans graphiques."
        )
        #expect(
            summary.commonGroupsText(bundle: try Self.bundle("en"), locale: Self.english)
                == "2 groups in common: Club de Belleville and BD & romans graphiques."
        )
    }

    @Test func noGroupInCommonNoLine() throws {
        let paul: NetworkReaderNode = try #require(r1.reader(id: "paul"))
        let ariane: NetworkReaderNode = try #require(r1.reader(id: "ariane"))

        #expect(NetworkReaderSummary(reader: paul, in: r1).commonGroupsText() == nil)
        #expect(NetworkReaderSummary(reader: ariane, in: r1).commonGroupsText() == nil)
    }

    @Test func memberSinceAsTheReaderRowsSayIt() throws {
        let reader: NetworkReaderNode = .init(
            reader: .init(id: "camille", username: "Camille", created: 1_615_809_600_000),
            state: .friend,
            isIsolated: false
        )
        let summary: NetworkReaderSummary = .init(reader: reader, commonGroups: [])

        #expect(summary.memberSinceText(bundle: try Self.bundle("fr"), locale: Self.french) == "Membre depuis mars 2021")
        #expect(
            NetworkReaderSummary(
                reader: .init(reader: .init(id: "x", username: "x"), state: .friend, isIsolated: true),
                commonGroups: []
            ).memberSinceText() == nil
        )
    }
}
