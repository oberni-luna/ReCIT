//
//  NewBookAuthor.swift
//  ReCIT_iOS
//
//  One author of a work being created: someone inventaire.io already has, named by uri, or
//  someone nobody has entered yet, described by name.
//
//  That single distinction is what keeps the base free of twin authors. Two « Ursula K. Le
//  Guin » split her bibliography in half, and only a human with merge rights can put it back.
//
//  See PRD 0015 and PRD 0021.
//

import Foundation

struct NewBookAuthor: Hashable, Identifiable, Sendable {

    /// The row's own identity, so two authors of the same name stay two rows.
    let id: UUID

    /// The name as inventaire.io has it, or as the reader typed it. Becomes a label on a new
    /// author entity — or nothing at all, when `uri` names an existing one.
    var name: String

    /// The uri of an author inventaire.io already has. `nil` means the author is being created:
    /// the seed then carries a label instead.
    var uri: String?

    /// What told this author apart from a namesake, kept only to show it back in the form.
    var description: String?

    init(
        id: UUID = .init(),
        name: String,
        uri: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.uri = uri
        self.description = description
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
