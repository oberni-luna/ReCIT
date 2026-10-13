//
//  NetworkGraphGroup.swift
//  ReCIT_iOS
//
//  A group as the Réseau graph needs one: what its card says — name, picture, my role, how many
//  members, who invited me, how many requests wait on me — and who is in it, to draw an edge to
//  each of my friends there (PRD 0019, Q7, Q9, Q22).
//
//  A value copied out of a `ReaderGroup` at the view boundary, so the graph's modules can run off
//  the main actor.
//

import Foundation

nonisolated struct NetworkGraphGroup: Hashable, Sendable {
    let id: String
    let name: String
    /// Already absolute, or `nil` when the group has none.
    let pictureURL: String?
    let role: NetworkGroupRole
    /// Its admins and members — the only people an edge can join it to (Q7).
    let memberIds: [String]
    /// What « N membres » counts: admins and members, friends of mine or not (Q8).
    let memberCount: Int
    /// The handle of whoever invited me, for « Invitation de X »; `nil` when I am not invited or
    /// the store does not know them.
    let invitorUsername: String?
    /// The requests to join waiting on me — some only when I administer it (Q22).
    let pendingCount: Int

    init(
        id: String,
        name: String,
        pictureURL: String? = nil,
        role: NetworkGroupRole,
        memberIds: [String],
        memberCount: Int? = nil,
        invitorUsername: String? = nil,
        pendingCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.pictureURL = pictureURL
        self.role = role
        self.memberIds = memberIds
        self.memberCount = memberCount ?? memberIds.count
        self.invitorUsername = invitorUsername
        self.pendingCount = pendingCount
    }
}
