//
//  UserDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation

struct ItemCountDTO: Codable {
    let `items:count`: Int
    let `items:last-add`: Double?
}

struct UserDTO: Codable {
    let _id: String
    let _rev: String?
    let username: String
    let email: String?
    let position: [Double]?
    let picture: String?
    let language: String?
    let snapshot: [String:ItemCountDTO]?
    /// When the account was opened, in milliseconds — inventaire's own epoch for user documents.
    ///
    /// Served on `/api/users/by-ids` for anyone, without a session, alongside the fields the
    /// cell already reads. Optional because the soft-deleted users the server keeps around to
    /// hold a username are the one shape that might not carry it.
    let created: Double?
    /// The few lines a reader writes about themself. Public: `/api/users/by-ids` serves it for
    /// anyone, which is why it lives on `User` and not with the owner's settings below.
    let bio: String?
    /// Whether the address has been confirmed through the link inventaire.io mailed. Served to
    /// the owner only, on `GET /api/user`, like the three fields after it.
    let validEmail: Bool?
    /// Whether the account can be followed from the fediverse.
    let fediversable: Bool?
    /// Days between two activity summaries; the server reads an absent value as 20.
    let summaryPeriodicity: Int?
    let settings: UserSettingsDTO?
}

//"snapshot": {
//                "network": {

struct UsersDTO: Codable {
    let users: [String: UserDTO]
}
