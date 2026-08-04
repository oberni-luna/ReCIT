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

    var isCurrent: Bool {
        !state.isFinished
    }

    var lastActionDate: Date {
        self.actions
            .sorted(by: { $0.timestamp < $1.timestamp })
            .last?.timestamp ?? created
    }

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
        case declined
        case cancelled

        /// A transaction in one of these states is over: no further transition is
        /// possible and users can no longer act on it.
        var isFinished: Bool {
            switch self {
            case .returned, .declined, .cancelled:
                true
            case .requested, .accepted, .confirmed:
                false
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

