//
//  GroupActionPayload.swift
//  ReCIT_iOS
//
//  The body of every `PUT /api/groups/<action>`: the group, and the other person when the
//  gesture is about someone else. `user` is left out of the JSON when it is `nil`.
//

import Foundation

struct GroupActionPayload: Codable {
    let group: String
    let user: String?
}
