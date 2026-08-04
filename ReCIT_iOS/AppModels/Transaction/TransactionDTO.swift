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

/// Response of `POST /api/transactions` (request action). The server wraps the
/// created transaction in a `transaction` key and may append a top-level
/// `warnings` array; unknown keys (including `warnings`) are ignored on decode.
struct PostTransactionResponseDTO: Codable {
    let transaction: TransactionDTO
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
