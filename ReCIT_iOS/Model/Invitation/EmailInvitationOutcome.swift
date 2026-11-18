//
//  EmailInvitationOutcome.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

/// What `POST /api/invitations/by-emails` did with the addresses it was sent, and the SnackBar
/// sentence that says it.
///
/// inventaire.io splits them in two: the addresses of an account get a friend request, or an
/// invitation to the group, and no mail; the others get its mail. Either list may come back
/// empty, both too when the server filtered everything out.
nonisolated struct EmailInvitationOutcome: Equatable, Sendable {
    /// The addresses inventaire.io mailed.
    let invitedAddresses: [String]
    /// The readers already on inventaire.io, who got a friend request or a group invitation.
    let existingUsernames: [String]
    /// Whether the invitations were to a group rather than to be friends.
    let isForGroup: Bool

    /// Whether a reader already on inventaire.io was sent something, which the store only learns
    /// from a fresh sync of the relations, or of the group.
    var hasExistingAccounts: Bool {
        existingUsernames.isEmpty == false
    }

    /// The SnackBar's sentence: how many addresses got the mail, and who already had an account.
    var message: LocalizedStringResource {
        let emailCount: Int = invitedAddresses.count
        guard let username = existingUsernames.first else {
            return emailCount == 0
                ? "network.email_invitation.sent"
                : "network.email_invitation.sent \(emailCount)"
        }

        return isForGroup
            ? groupInvitationMessage(username: username, emailCount: emailCount)
            : friendRequestMessage(username: username, emailCount: emailCount)
    }

    private func friendRequestMessage(
        username: String,
        emailCount: Int
    ) -> LocalizedStringResource {
        let readerCount: Int = existingUsernames.count
        return switch (emailCount, readerCount) {
        case (0, 1): "network.email_invitation.request_one \(username)"
        case (0, _): "network.email_invitation.request_many \(readerCount)"
        case (_, 1): "network.email_invitation.sent_and_request_one \(emailCount) \(username)"
        default: "network.email_invitation.sent_and_request_many \(emailCount) \(readerCount)"
        }
    }

    private func groupInvitationMessage(
        username: String,
        emailCount: Int
    ) -> LocalizedStringResource {
        let readerCount: Int = existingUsernames.count
        return switch (emailCount, readerCount) {
        case (0, 1): "network.email_invitation.group_invite_one \(username)"
        case (0, _): "network.email_invitation.group_invite_many \(readerCount)"
        case (_, 1): "network.email_invitation.sent_and_group_invite_one \(emailCount) \(username)"
        default: "network.email_invitation.sent_and_group_invite_many \(emailCount) \(readerCount)"
        }
    }
}
