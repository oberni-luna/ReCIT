//
//  TransactionDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//

import Foundation

struct TransactionsDTO: Codable {
    let transactions: [TransactionDTO]
}

struct TransactionDTO: Codable {
    let _id: String
    let _rev: String
    let item: String
    let owner: String
    let requester: String
    let transaction: String
    let state: String
    let created: Double
    let actions: [ActionDTO]
    let read: MessageReadStatusDTO
}

struct MessageReadStatusDTO: Codable {
    let owner: Bool
    let requester: Bool
}

struct ActionDTO: Codable {
    let action: String
    let timestamp: Double
}
