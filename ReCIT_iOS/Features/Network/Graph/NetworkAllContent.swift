//
//  NetworkAllContent.swift
//  ReCIT_iOS
//
//  What « Tout » shows: the graph around « Vous », or — when there is nobody and nothing to put
//  around me — the empty state E1 that says what will come there and the two first steps
//  (PRD 0019, Q39).
//
//  The rule is the graph's own: what counts is what the graph draws. My friends and the readers
//  waiting on my answer (Q5), the groups I am an admin or a member of, and the invitations I
//  received (Q4). What I sent — a friend request, a request to join — is never drawn (Q4, Q5), so
//  it does not make the network any less empty; it is still listed under Amis and Groupes.
//
//  A value built from values, so the rule is testable without a store.
//

import Foundation

enum NetworkAllContent: Equatable {
    /// Nobody and nothing around me: « Vous », a sentence, and the ways to start.
    case empty
    /// Something to draw around « Vous ».
    case graph

    /// - Parameters:
    ///   - relations: Where I stand with each reader in the store, myself left out.
    ///   - groups: My groups, sorted by where I stand in each.
    init(
        relations: some Sequence<UserRelation>,
        groups: MyGroups
    ) {
        let hasReader: Bool = relations.contains { $0 == .friend || $0 == .requestReceived }
        let hasGroup: Bool = groups.mine.isEmpty == false || groups.invitations.isEmpty == false
        self = hasReader || hasGroup ? .graph : .empty
    }
}
