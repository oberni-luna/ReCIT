//
//  GroupRole.swift
//  ReCIT_iOS
//
//  The five lists a group document keeps people in (`server/models/attributes/group.ts`,
//  `groupRoles`). Someone is in at most one of them.
//

import Foundation

enum GroupRole: String, CaseIterable, Sendable {
    case admin
    case member
    /// Invited by a member, not answered yet.
    case invited
    /// Turned an invitation down. Cannot be invited again, but a request of theirs is accepted
    /// on the spot.
    case declined
    /// Asked to join a group that is not open, waiting on an admin.
    case requested

    /// Admins and members: the people the group's books are shared with.
    var belongs: Bool {
        self == .admin || self == .member
    }
}
