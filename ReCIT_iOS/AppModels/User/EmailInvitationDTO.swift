//
//  EmailInvitationDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

/// The answer of `POST /api/invitations/by-emails`: `users`, the accounts that got a friend
/// request or a group invitation, and `emails`, the addresses that got a mail. Read leniently,
/// a missing key being an empty list.
nonisolated struct EmailInvitationDTO: Codable, Sendable {
    let users: [EmailInvitationUserDTO]
    let emails: [String]

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        users = try container.decodeIfPresent([EmailInvitationUserDTO].self, forKey: .users) ?? []
        emails = try container.decodeIfPresent([String].self, forKey: .emails) ?? []
    }
}
