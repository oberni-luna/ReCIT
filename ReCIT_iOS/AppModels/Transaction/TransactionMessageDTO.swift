//
//  TransactionMessageDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/02/2026.
//

import Foundation

struct TransactionMessagesDTO: Codable {
    let messages: [TransactionMessageDTO]
}

struct TransactionMessageDTO: Codable {
    let _id: String
    let _rev: String
    let user: String
    let message: String
    let created: Double
    let transaction: String
}
