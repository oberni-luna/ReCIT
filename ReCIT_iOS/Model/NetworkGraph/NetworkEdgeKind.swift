//
//  NetworkEdgeKind.swift
//  ReCIT_iOS
//
//  The five kinds of line in the Réseau graph (PRD 0019, Q4, Q5, Q7, Q32 bis). The style of each
//  is the view's business; whether it is dashed is the graph's: a dashed line is something that
//  waits on my answer — an invitation, a friend request.
//

import Foundation

nonisolated enum NetworkEdgeKind: Hashable, Sendable {
    /// « Vous » ↔ a group I administer or belong to.
    case meToGroup
    /// « Vous » ↔ a group that invited me: dashed.
    case meToInvitation
    /// A friend ↔ a group they administer or belong to (Q7).
    case friendToGroup
    /// « Vous » ↔ a friend.
    case meToFriend
    /// « Vous » ↔ a reader who asked to be my friend: dashed (Q5b).
    case meToRequester

    var isDashed: Bool {
        self == .meToInvitation || self == .meToRequester
    }

    /// Whether the line runs between « Vous » and a reader — the lighter line (Q32 bis).
    var joinsMeToReader: Bool {
        self == .meToFriend || self == .meToRequester
    }
}
