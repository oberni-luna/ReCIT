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

    /// The canonical uri of the edition this request was about, whether the server created it
    /// or found it already there — a reader publishing a book somebody else added a minute ago
    /// gets the existing one, which is the right answer and not an error.
    var editionUri: String? {
        entries.first?.edition?.uri
    }
}
