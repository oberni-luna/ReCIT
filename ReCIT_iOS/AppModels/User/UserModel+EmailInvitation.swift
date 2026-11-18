//
//  UserModel+EmailInvitation.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

extension UserModel {
    /// Sends « Inviter par e-mail » through `POST /api/invitations/by-emails`: a friend request,
    /// or a group invitation, to the addresses of an account, and inventaire.io's mail to the
    /// others.
    ///
    /// Server first, not optimistic: nothing of it lives in the store before the answer, which
    /// alone says who had an account. It does not sync either; when `hasExistingAccounts`, the
    /// caller refreshes the relations, or the group, so the readers show as asked.
    /// - Parameters:
    ///   - list: The addresses to invite, read from the field.
    ///   - message: The text added to the mail; a blank one is not sent.
    ///   - target: To be friends, or into a group.
    /// - Returns: Who got a mail and who got a request.
    /// - Throws: `EmailInvitationFailure.rateLimited` past the quota, `.other` otherwise.
    func sendEmailInvitations(
        _ list: EmailInvitationList,
        message: String,
        to target: EmailInvitationTarget
    ) async throws(EmailInvitationFailure) -> EmailInvitationOutcome {
        let payload: EmailInvitationPayload = .init(
            emails: list.addresses,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : message,
            group: target.groupId
        )

        let answer: EmailInvitationDTO?
        do {
            answer = try await apiService.send(
                toEndpoint: "/api/invitations/by-emails",
                method: "POST",
                payload: payload
            )
        } catch {
            throw EmailInvitationFailure(error: error)
        }

        return .init(
            invitedAddresses: answer?.emails ?? [],
            existingUsernames: answer?.users.map(\.username) ?? [],
            target: target
        )
    }
}
