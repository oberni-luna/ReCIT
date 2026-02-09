//
//  TransactionMessage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//
import Foundation
import SwiftData

@Model
public class TransactionMessage: Identifiable, Equatable {
    @Attribute(.unique) var _id: String
    var user: User
    var message: String
    var created: Date
    var transaction: UserTransaction?

    init(_id: String, user: User, message: String, created: Date, transaction: UserTransaction? = nil) {
        self._id = _id
        self.user = user
        self.message = message
        self.created = created
        self.transaction = transaction
    }
}
