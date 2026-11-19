//
//  EmailInvitationUserDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation

/// One account of `EmailInvitationDTO.users`. The server sends the whole user; the SnackBar
/// names it, and that is all the app reads.
nonisolated struct EmailInvitationUserDTO: Codable, Sendable {
    let username: String
}
