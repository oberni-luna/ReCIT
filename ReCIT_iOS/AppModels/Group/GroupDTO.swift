//
//  GroupDTO.swift
//  ReCIT_iOS
//
//  A group document as inventaire.io serves it — `GET /api/groups`, `/api/groups/by-id`, and the
//  answer to `POST /api/groups`. Checked against a live document on 2026-09-27.
//
//  Everything but the id, the name and the two lists every group has is optional: the server
//  writes `null` for an invitor, omits `picture` and `description` when there are none, and
//  older documents predate `open`.
//

import Foundation

struct GroupDTO: Codable {
    let _id: String
    let _rev: String?
    let name: String
    let slug: String?
    let description: String?
    let picture: String?
    let searchable: Bool?
    let open: Bool?
    let admins: [GroupMembership]
    let members: [GroupMembership]
    let invited: [GroupMembership]?
    let declined: [GroupMembership]?
    let requested: [GroupMembership]?
}
