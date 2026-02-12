//
//  Transaction.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//
import Foundation
import SwiftData

@Model
public class UserTransaction: Identifiable, Equatable, Hashable {
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

    enum TransactionState: String, Codable, Hashable {
        case requested
        case accepted
        case confirmed
        case returned

        var systemImage: String {
            switch self {
            case .requested:
                "questionmark.message.fill"
            case .accepted:
                "checkmark.message.fill"
            case .confirmed:
                "hand.thumbsup.circle.fill"
            case .returned:
                "checkmark.square.fill"
            }
        }
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

