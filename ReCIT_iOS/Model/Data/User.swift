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
//    @Relationship(deleteRule: .cascade, inverse: \Item.owner) var items = [Item]()

    init(_id: String, _rev: String, username: String, email: String?, position: Coordinates?, avatarURLValue: String?) {
        self._id = _id
        self._rev = _rev
        self.username = username
        self.email = email
        self.position = position
        self.avatarURLValue = avatarURLValue
    }

    public static func == (lhs: User, rhs: User) -> Bool {
        lhs._id == rhs._id && lhs._rev == rhs._rev
    }

    convenience init(userDTO: UserDTO) {
        let position: Coordinates? = if let positionArray = userDTO.position, positionArray.count == 2 {
            Coordinates(latitude: positionArray[0], longitude: positionArray[1])
        } else { nil }

        self.init(
            _id: userDTO._id,
            _rev: userDTO._rev,
            username: userDTO.username,
            email: userDTO.email,
            position: position,
            avatarURLValue: userDTO.picture
        )
    }
}
