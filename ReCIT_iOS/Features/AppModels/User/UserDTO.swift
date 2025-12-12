//
//  UserDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation

struct ItemCountDTO: Codable {
    let `items:count`: Int
    let `items:last-add`: Int?
}

struct UserDTO: Codable {
    let _id: String
    let _rev: String?
    let username: String
    let email: String?
    let position: [Double]?
    let picture: String?
    let language: String?
}

struct UsersDTO: Codable {
    let users: [String: UserDTO]
}
