//
//  PasswordChangePayload.swift
//  ReCIT_iOS
//
//  The body of `PUT /api/auth/password`, under the server's hyphenated names.
//

import Foundation

struct PasswordChangePayload: Codable {
    let currentPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "old-password"
        case newPassword = "new-password"
    }
}
