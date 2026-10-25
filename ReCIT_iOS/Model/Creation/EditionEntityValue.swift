//
//  EditionEntityValue.swift
//  ReCIT_iOS
//
//  An entity an edition names: its publisher, its collection, its language, one of the people
//  who made it. One inventaire.io or Wikidata already has, named by uri — or one nobody has
//  entered yet, described by the name the reader typed, and created before the claim that names
//  it is sent.
//
//  The same distinction as `NewBookAuthor`'s, for the same reason: a second « Gallimard » on
//  inventaire.io splits a catalogue in two, and only a human with merge rights can join it again.
//

import Foundation

struct EditionEntityValue: Hashable, Identifiable, Sendable {

    /// The row's own identity, so two namesakes stay two rows, and so a created entity can be
    /// found again to receive its uri.
    let id: UUID

    /// `nil` while the entity is still to be created.
    var uri: String?

    /// What the form prints: the entity's label, or the name typed for one to create.
    var label: String

    /// What tells it apart from a namesake, as the search answered it.
    var detail: String?

    init(
        id: UUID = .init(),
        uri: String? = nil,
        label: String,
        detail: String? = nil
    ) {
        self.id = id
        self.uri = uri
        self.label = label
        self.detail = detail
    }

    var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The same entity: the same uri, or — for one still to be created — the same name.
    func isSame(as other: EditionEntityValue) -> Bool {
        if let uri, let otherUri = other.uri { return uri == otherUri }
        if uri != nil || other.uri != nil { return false }
        return trimmedLabel.localizedCaseInsensitiveCompare(other.trimmedLabel) == .orderedSame
    }
}
