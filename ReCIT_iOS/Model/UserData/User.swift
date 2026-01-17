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
    var lastInventorySync: Double = 0
    @Relationship(deleteRule: .cascade, inverse: \InventoryItem.owner) var items: [InventoryItem] = []

    init(_id: String, _rev: String, username: String, email: String?, position: Coordinates?, avatarURLValue: String?, lastItemAdded: Double = 0) {
        self._id = _id
        self._rev = _rev
        self.username = username
        self.email = email
        self.position = position
        self.avatarURLValue = avatarURLValue
        self.lastItemAdded = lastItemAdded
    }

    public static func == (lhs: User, rhs: User) -> Bool {
        lhs._id == rhs._id && lhs._rev == rhs._rev
    }

    public func update(with user: User) {
        if self._rev != user._rev {
            self._id = user._id
            self._rev = user._rev
            self.username = user.username
            self.email = user.email
            self.position = user.position
            self.avatarURLValue = user.avatarURLValue
            self.lastItemAdded = user.lastItemAdded
        }
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
            lastItemAdded: userDTO.snapshot?.values.map { $0.`items:last-add` ?? 0 }.max() ?? 0
        )
    }
}
