//
//  User.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import Foundation
import SwiftData

public struct Coordinates: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

@Model
public class User: Identifiable, Equatable {
    @Attribute(.unique) var _id: String
    var _rev: String
    var username: String
    var email: String?
    var position: Coordinates?
    var avatarURLValue: String?
    var lastItemAdded: Double = 0
    var itemCount: Int = 0
    /// Timestamp (ms) of the last successful inventory sync, or `nil` if this
    /// user's inventory has never been synced. Used to show a syncing placeholder
    /// instead of an ambiguous empty inventory.
    var lastInventorySync: Double?
    @Relationship(deleteRule: .cascade, inverse: \InventoryItem.owner) var items: [InventoryItem] = []

    init(_id: String, _rev: String, username: String, email: String?, position: Coordinates?, avatarURLValue: String?, itemCount: Int, lastItemAdded: Double = 0) {
        self._id = _id
        self._rev = _rev
        self.username = username
        self.email = email
        self.position = position
        self.avatarURLValue = avatarURLValue
        self.itemCount = itemCount
        self.lastItemAdded = lastItemAdded
    }

    public static func == (lhs: User, rhs: User) -> Bool {
        lhs._id == rhs._id && lhs._rev == rhs._rev
    }

    /// Merges a freshly fetched user into this one, in place.
    ///
    /// The merge used to be gated on `_rev` changing, and so never ran: inventaire's user
    /// payloads (`/api/user`, `/api/users/by-ids`) carry no `_rev` at all, so both sides read
    /// `""` and every sync was a no-op. A user stored once was frozen for good — which is why
    /// the profile's item count stayed put even across a relaunch, and why `lastItemAdded`
    /// never moved, leaving `InventoryModel.syncInventory` convinced there was nothing new to
    /// fetch after the first sync.
    ///
    /// Fields the server omits are left alone (ADR 0001): a sparse payload must not wipe good
    /// local data. `itemCount` and `lastItemAdded` are always written, because an absent
    /// snapshot genuinely means "no items visible to you".
    public func update(with user: User) {
        if user._rev.isEmpty == false {
            self._rev = user._rev
        }
        self.username = user.username
        if let email = user.email {
            self.email = email
        }
        if let position = user.position {
            self.position = position
        }
        if let avatarURLValue = user.avatarURLValue {
            self.avatarURLValue = avatarURLValue
        }
        self.itemCount = user.itemCount
        self.lastItemAdded = user.lastItemAdded
    }

    convenience init(userDTO: UserDTO, baseUrl: String) {
        let position: Coordinates? = if let positionArray = userDTO.position, positionArray.count == 2 {
            Coordinates(latitude: positionArray[0], longitude: positionArray[1])
        } else { nil }

        self.init(
            _id: userDTO._id,
            _rev: userDTO._rev ?? "",
            username: userDTO.username,
            email: userDTO.email,
            position: position,
            avatarURLValue: userDTO.picture != nil ? "\(baseUrl)\(userDTO.picture ?? "")" : nil,
            itemCount: userDTO.snapshot?.values.map { $0.`items:count` }.max() ?? 0,
            lastItemAdded: userDTO.snapshot?.values.map { $0.`items:last-add` ?? 0 }.max() ?? 0
        )
    }
}
