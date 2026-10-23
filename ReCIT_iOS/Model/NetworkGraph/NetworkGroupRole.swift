//
//  NetworkGroupRole.swift
//  ReCIT_iOS
//
//  Where I stand in a group the Réseau graph draws: admin, member, or invited (PRD 0019, Q4).
//  The other two roles of a group document never reach the graph — a request I sent stays in the
//  Groupes list, a declined invitation is gone — so they have no case here.
//
//  Ordered as the ring is (Q18): admin first, then member, then invitation.
//
//  Not `GroupRole`: that one belongs to the main actor like the rest of the target, and the
//  graph's modules run off it. `nonisolated`, so they can compare and sort with it.
//

import Foundation

nonisolated enum NetworkGroupRole: Int, Comparable, Hashable, Sendable {
    case admin
    case member
    case invited

    /// Admins and members: what the counter counts and what makes a group « in common » (Q10,
    /// Q27 bis). An invitation is drawn, not counted.
    var belongs: Bool {
        self != .invited
    }

    static func < (lhs: NetworkGroupRole, rhs: NetworkGroupRole) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
