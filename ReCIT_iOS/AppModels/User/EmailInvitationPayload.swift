//
//  EmailInvitationPayload.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

/// The body of `POST /api/invitations/by-emails`. `message` and `group` are left out of the JSON
/// when `nil`: the server reads an absent key, not an empty one.
nonisolated struct EmailInvitationPayload: Codable, Sendable {
    let emails: [String]
    let message: String?
    let group: String?
}
