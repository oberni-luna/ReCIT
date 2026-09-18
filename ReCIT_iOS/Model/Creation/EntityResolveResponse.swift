//
//  EntityResolveResponse.swift
//  ReCIT_iOS
//
//  What `POST /api/entities/resolve` answers: the same entries, with each seed told apart —
//  `uri` once it is known, `resolved` when the server matched an entity that already existed,
//  `created` when it made one.
//
//  The uri of the edition is the **canonical** one — inventaire's own `inv:…` id — and it is
//  what an inventory item has to be created from. Never the `isbn:` uri the lookup asked with:
//  matching one against the other is the mistake `BatchScanViewModel.isAlreadyOwned` documents,
//  and it quietly duplicates books.
//
//  See PRD 0015.
//

import Foundation

struct EntityResolveResponse: Codable, Equatable, Sendable {

    let entries: [Entry]

    struct Entry: Codable, Equatable, Sendable {
        let edition: Seed?
        let works: [Seed]?
        let authors: [Seed]?
    }

    struct Seed: Codable, Equatable, Sendable {
        let uri: String?
        let resolved: Bool?
        let created: Bool?
    }

    /// The uri of a work the server **recognised** — not one it created, and not one it merely
    /// echoed back. This is what the reconnaissance pass is run for: a work already on
    /// inventaire.io means the book being added is one more edition of it.
    var resolvedWorkUri: String? {
        entries.first?.works?.first(where: { $0.resolved == true })?.uri
    }

    /// The canonical uri of the edition this request was about, whether the server created it
    /// or found it already there — a reader publishing a book somebody else added a minute ago
    /// gets the existing one, which is the right answer and not an error.
    var editionUri: String? {
        entries.first?.edition?.uri
    }
}
