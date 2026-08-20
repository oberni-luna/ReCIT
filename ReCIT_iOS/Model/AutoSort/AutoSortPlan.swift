//
//  AutoSortPlan.swift
//  ReCIT_iOS
//
//  Phase 3, and the thing the review screen renders. Plain code: each book
//  inherits its genre's étagère, and nothing else happens.
//
//  This is the step that issue 0024 will turn into writes, which is why no model
//  is involved in it. It can only ever name an étagère the validated mapping
//  named, and the validated mapping can only ever name one phase 1 declared — so
//  the mutation cannot invent anything, by construction rather than by care.
//
//  Two kinds of book are left out, and both are left *unshelved* rather than
//  swept into a catch-all: one with no genre at all, and one whose genre the
//  mapping does not cover. Filing either would be filing on a guess.
//
//  Pure by design — no store, no model, no SwiftUI. See PRD 0006.
//

import Foundation

struct AutoSortPlan: Equatable, Sendable {

    /// One étagère as proposed: a name the user will read, and the books it would
    /// hold. Never empty — an étagère with nothing on it is dropped before it gets
    /// here.
    struct ProposedShelf: Identifiable, Equatable, Sendable {
        let name: String
        let books: [AutoSortBook]

        var id: String { name }

        /// Derived, not stored, so the count on screen can never disagree with the
        /// list under it.
        var bookCount: Int { books.count }
    }

    /// In the order phase 1 declared the étagères, minus the ones that ended up
    /// empty. Declaration order rather than size order: it is the order the model
    /// itself thought the collection reads in, and re-sorting would silently
    /// second-guess phase 1.
    let shelves: [ProposedShelf]

    /// Books the plan does not touch, in the order they came in.
    let leftUnshelved: [AutoSortBook]

    var isEmpty: Bool { shelves.isEmpty }

    var shelvedBookCount: Int {
        shelves.reduce(0) { $0 + $1.bookCount }
    }

    init(mapping: ValidatedGenreMapping, books: [AutoSortBook]) {
        var booksByShelf: [String: [AutoSortBook]] = [:]
        var leftOut: [AutoSortBook] = []

        for book in books {
            guard let key = book.primaryGenreKey, let shelf = mapping.shelfByGenreKey[key] else {
                leftOut.append(book)
                continue
            }
            booksByShelf[shelf, default: []].append(book)
        }

        shelves = mapping.shelfNames.compactMap { name in
            guard let books = booksByShelf[name], !books.isEmpty else { return nil }
            return ProposedShelf(name: name, books: books)
        }
        leftUnshelved = leftOut
    }

    /// A plan that proposes nothing, for the honest outcome where no unshelved book
    /// carries any genre at all. Kept as an initialiser rather than a `nil` plan so
    /// the review screen can say "these books stayed put" instead of showing an
    /// error it has no reason to show.
    init(nothingToPropose books: [AutoSortBook]) {
        shelves = []
        leftUnshelved = books
    }
}
