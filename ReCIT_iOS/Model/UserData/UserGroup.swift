//
//  User.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import Foundation
import SwiftData

@Model
public class UserGroup: Identifiable, Equatable {
    @Attribute(.unique) var _id: String
    var _rev: String
    var name: String
    var slug: String
    var pictureURL: String?

    @Relationship(deleteRule: .cascade, inverse: \InventoryItem.owner) var members: [User] = []

    init(_id: String, _rev: String, name: String, slug: String, pictureURL: String? = nil, members: [User] = []) {
        self._id = _id
        self._rev = _rev
        self.name = name
        self.slug = slug
        self.pictureURL = pictureURL
        self.members = members
    }

    
}
