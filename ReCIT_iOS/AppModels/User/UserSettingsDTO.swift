//
//  UserSettingsDTO.swift
//  ReCIT_iOS
//
//  The `settings` object of `GET /api/user`, as inventaire.io stores it: two groups of booleans
//  keyed by the names `PUT /api/user` takes after `settings.<group>.`. A key the account never
//  touched is simply absent, and the server reads absent as `true` for both groups
//  (`notifications[label] === false`, `anonymize !== false`) — `AccountSettings` does the same.
//

import Foundation

struct UserSettingsDTO: Codable {
    let notifications: [String: Bool]?
    let contributions: [String: Bool]?
}
