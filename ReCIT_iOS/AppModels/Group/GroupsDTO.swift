//
//  GroupsDTO.swift
//  ReCIT_iOS
//
//  `GET /api/groups`: the groups where I am admin, member or invited — **not** those I asked to
//  join, which is why `GroupRequestLedger` exists.
//

import Foundation

struct GroupsDTO: Codable {
    let groups: [GroupDTO]
}
