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
}

//"snapshot": {
//                "network": {

struct UsersDTO: Codable {
    let users: [String: UserDTO]
}
