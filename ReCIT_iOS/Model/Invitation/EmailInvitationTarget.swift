//
//  EmailInvitationTarget.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

/// What « Inviter par e-mail » invites to: to be my friends, or into a group. The server sends a
/// friend request or the group's invitation to an address that has an account, and the copy of
/// every screen of the flow follows.
nonisolated enum EmailInvitationTarget: Equatable, Sendable {
    case friends
    case group(id: String)

    /// The `group` of `POST /api/invitations/by-emails`: the group's id, `nil` for friends.
    var groupId: String? {
        switch self {
        case .friends: nil
        case let .group(id): id
        }
    }
}
