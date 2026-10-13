//
//  NetworkGroupSummary.swift
//  ReCIT_iOS
//
//  What the sheet of a group touched in the Réseau graph says (PRD 0019, R2, Q29, Q29 bis):
//  « Admin · 12 membres, dont 4 de vos amis : Inès, Léa, Rémi et Camille. », and the avatars of
//  those friends, five at most.
//
//  - The sentence opens on the card's own words for my role and the members — « Admin · 12
//    membres » or « 12 membres » — and an invitation, whose card names who sent it, says its
//    members here.
//  - With no friend of mine in the group, it stops there: « 48 membres. »
//  - Otherwise it counts them and names them by `NetworkNameList`.
//
//  The words are put together by `NetworkGroupSummary+Text`; this is what they are made of, so the
//  rule is tested without a catalogue.
//

import Foundation

nonisolated struct NetworkGroupSummary: Hashable, Sendable {
    /// The most avatars the sheet lines up (Q29).
    static let maximumAvatars: Int = 5

    let name: String
    /// My role and the members, as the card says them — never the invitation's sender.
    let lead: NetworkGroupCardDetail
    /// My friends in the group, all of them.
    let friendCount: Int
    /// The friends the sentence names.
    let friendNames: NetworkNameList
    /// The friends whose avatars are lined up, in the order they are named.
    let avatars: [NetworkGraphReader]

    /// - Parameters:
    ///   - group: The group touched.
    ///   - friends: My friends who administer it or belong to it, in the order to name them.
    init(
        group: NetworkGraphGroup,
        friends: [NetworkGraphReader]
    ) {
        name = group.name
        lead = group.role == .admin
            ? .admin(memberCount: group.memberCount)
            : .members(count: group.memberCount)
        friendCount = friends.count
        friendNames = .init(friends.map(\.username))
        avatars = Array(friends.prefix(Self.maximumAvatars))
    }

    /// The summary of `group` in `graph`, naming its friends by handle.
    init(
        group: NetworkGraphGroup,
        in graph: NetworkGraph
    ) {
        self.init(group: group, friends: graph.friends(in: group.id))
    }

    /// Whether the sentence goes on past the members: some friend of mine is in the group.
    var namesFriends: Bool {
        friendCount > 0
    }
}
