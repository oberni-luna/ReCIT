//
//  GroupCreationPayload.swift
//  ReCIT_iOS
//
//  The body of `POST /api/groups`. `position` exists on the server and is not offered yet.
//

import Foundation

struct GroupCreationPayload: Codable {
    let name: String
    let description: String
    let searchable: Bool
    let open: Bool
}
