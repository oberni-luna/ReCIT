//
//  Transaction.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//
import Foundation
import SwiftData

@Model
public class UserTransaction: Identifiable, Equatable {
    @Attribute(.unique) var _id: String
    var _rev: String
    var item: InventoryItem
    var owner: User
    var requester: User
    var type: TransactionType
    var created: Date
    var state: TransactionState
    var actions: [TransactionAction]
    var readStatus: MessageReadStatus

    @Relationship(deleteRule: .cascade, inverse: \TransactionMessage.transaction) var messages: [TransactionMessage]

    init(_id: String, _rev: String, item: InventoryItem, owner: User, requester: User, type: TransactionType, created: Date, messages: [TransactionMessage], state: TransactionState, actions: [TransactionAction], readStatus: MessageReadStatus) {
        self._id = _id
        self._rev = _rev
        self.item = item
        self.owner = owner
        self.requester = requester
        self.type = type
        self.created = created
        self.messages = messages
        self.state = state
        self.actions = actions
        self.readStatus = readStatus
    }

    enum TransactionState: Codable {
        case requested
        case accepted
        case confirmed
        case returned
    }

    struct TransactionAction: Codable, Equatable {
        var action: TransactionState
        var timestamp: Date
    }

    struct MessageReadStatus: Codable, Equatable {
        var owner: Bool
        var requester: Bool
    }
}

