//
//  NetworkGraphReader.swift
//  ReCIT_iOS
//
//  A reader as the Réseau graph needs one — me, a friend, or someone waiting on my answer: an id,
//  a handle for the name and the initials, a picture, and the day the account was opened, for
//  the sheets that will say « Membre depuis … » (PRD 0019).
//
//  A value copied out of the store's `User` at the view boundary, so the graph's modules never
//  touch SwiftData and can run off the main actor.
//

import Foundation

nonisolated struct NetworkGraphReader: Hashable, Sendable {
    let id: String
    let username: String
    /// Already absolute, or `nil` when the reader has no picture.
    let pictureURL: String?
    /// When the account was opened, in milliseconds, or `nil` when the server has not said.
    let created: Double?

    init(
        id: String,
        username: String,
        pictureURL: String? = nil,
        created: Double? = nil
    ) {
        self.id = id
        self.username = username
        self.pictureURL = pictureURL
        self.created = created
    }
}
