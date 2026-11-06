//
//  NewBookOrigin.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation

/// Where « Nouveau livre » was opened from, which decides what it opens on and whether its ISBN
/// can be typed. Also the identity of a draft: the same barcode, or the same query, reopens it.
enum NewBookOrigin: Hashable, Identifiable, Sendable {
    /// A barcode the scanner read and inventaire.io did not know. Its ISBN is never edited.
    case scan(isbn: String)

    /// A query Recherche found nothing for on inventaire.io. The ISBN is a field to fill in.
    case search(query: String)

    var id: Self { self }

    /// The ISBN the reader came with: the barcode, or a query that was one. `nil` for a text query.
    var isbn: String? {
        switch self {
        case .scan(let isbn):
            isbn
        case .search(let query):
            IsbnQuery.isbn(in: query)
        }
    }

    /// Whether the edition's form lets the ISBN be typed.
    var isISBNEditable: Bool {
        switch self {
        case .scan:
            false
        case .search:
            true
        }
    }

    /// What the work search opens on: a text query, as typed in Recherche. Empty after a scan, or
    /// after a query that was an ISBN, which says nothing about the work.
    var workQuery: String {
        guard case .search(let query) = self, isbn == nil else { return "" }
        return query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The draft the form starts from when there is none to resume.
    var blankDraft: NewBookDraft {
        .init(isbn: isbn ?? "")
    }
}
