//
//  SortSnapshot.swift
//  ReCIT_iOS
//
//  The library as it stood when the sorting screen opened: every étagère, every book,
//  and which books each étagère holds — in value types, frozen.
//
//  Frozen because the screen is a **draft, not a display**. The reasoning, and the
//  ADR 0001 departure it amounts to, is written where the freeze happens
//  (`SortSessionModel.freeze`); what matters here is the consequence: nothing in this
//  type refers to a `@Model`, so the projection over it is pure and testable without
//  a store.
//
//  Membership is kept as the store gives it — ids per étagère, possibly overlapping,
//  since `Shelf ⇄ InventoryItem` is many-to-many and a book on two étagères appears on
//  both (ADR 0003). Making that overlap a partition is `SortProjection`'s job, not
//  this type's: the snapshot's contract is to say what the server holds, and a
//  snapshot that quietly dropped a membership would be lying about it.
//
//  See PRD 0008.
//

import Foundation

struct SortSnapshot: Equatable, Sendable {

    /// One étagère, reduced to what sorting needs of it: what it is called and what
    /// the store says is on it.
    struct Shelf: Identifiable, Equatable, Sendable {
        /// The server `Shelf._id`.
        let id: String
        let name: String
        /// The `InventoryItem._id`s the store links to this étagère. May overlap
        /// another étagère's — see the note above.
        let bookIds: [String]
    }

    /// Every étagère of the user, in the order the screen should show them.
    let shelves: [Shelf]

    /// Every book of the user's inventory, in the order the screen should show them.
    /// Order within a section is not part of the session's state (PRD 0008), so this
    /// one order is what every section reads in.
    let books: [AutoSortBook]

    init(shelves: [Shelf] = [], books: [AutoSortBook] = []) {
        self.shelves = shelves
        self.books = books
    }

    /// What the screen holds before its opening sync has landed.
    static let empty: SortSnapshot = .init()
}
