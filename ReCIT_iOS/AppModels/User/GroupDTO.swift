//
//  UserDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation

struct GroupsDTO: Codable {
    let groups: [GroupsDTO]
}

struct GroupDTO: Codable {
    let _id: String
    let _rev: String
    let name: String
    let slug: String?
    let picture: String?
    let admins: [GroupMemberDTO]
    let members: [GroupMemberDTO]

    init(_id: String, _rev: String, name: String, slug: String?, picture: String?, admins: [GroupMemberDTO], members: [GroupMemberDTO]) {
        self._id = _id
        self._rev = _rev
        self.name = name
        self.slug = slug
        self.picture = picture
        self.admins = admins
        self.members = members
    }
}

struct GroupMemberDTO: Codable {
    let user: String
    let invitor: String
    let timestamp: Double

    init(user: String, invitor: String, timestamp: Double) {
        self.user = user
        self.invitor = invitor
        self.timestamp = timestamp
    }
}
