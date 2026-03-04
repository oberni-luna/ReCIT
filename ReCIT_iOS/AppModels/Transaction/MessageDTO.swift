//
//  MessageDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//

import Foundation

struct MessagesDTO: Codable {
    let messages: [MessageDTO]
}

struct MessageDTO: Codable {
    let _id: String
    let _rev: String
    let user: String
    let message: String
    let created: Double
    let transaction: String
}
