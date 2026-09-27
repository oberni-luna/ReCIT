//
//  GroupByIdDTO.swift
//  ReCIT_iOS
//
//  `GET /api/groups/by-id`: the group, and the people it names, already shaped as users.
//

import Foundation

struct GroupByIdDTO: Codable {
    let group: GroupDTO
    let users: [UserDTO]
}
