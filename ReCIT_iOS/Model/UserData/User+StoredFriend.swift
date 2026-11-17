//
//  User+StoredFriend.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 17/11/2026.
//

import SwiftData

extension User {
    /// A friend whose row is still in the store. Asked before anything else is read: reading
    /// `relation` off a deleted row is a hard trap, not a `nil`.
    var isStoredFriend: Bool {
        isStillInTheStore && relation == .friend
    }
}
