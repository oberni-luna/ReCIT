//
//  GroupMembership.swift
//  ReCIT_iOS
//
//  One person's place in a group, as inventaire.io stores it: who, who brought them in, and
//  since when. Every one of a group's five role lists is a list of these.
//

import Foundation

struct GroupMembership: Codable, Equatable, Hashable, Sendable {
    let user: String
    /// Who invited them, or `nil` for the creator and for a request — the server writes `null`,
    /// which is what the old `GroupMemberDTO` could not decode.
    let invitor: String?
    let timestamp: Double?
}
