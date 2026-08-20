//
//  SortSection.swift
//  ReCIT_iOS
//
//  One band of the sorting surface: an étagère that exists on the server, an étagère
//  the user has drafted but not yet created, or the pile of books that are on none.
//
//  The three cases are one type rather than three because every rule on this screen
//  treats them alike — a book is dragged out of any of them and into any of them, and
//  the projection's invariant is that it sits in exactly one. Only the write plan
//  (slice 0040) ever has to tell them apart, and it does so on `id`.
//
//  The draft case carries no members of its own: membership lives entirely in the
//  change stack, so a draft is a name and an id until the projection fills it. It is
//  declared here rather than added when slice 0041 needs it, because a value type that
//  has to grow a third case later is a value type every switch has to be revisited for.
//
//  Pure by design — no store, no SwiftUI. See PRD 0008.
//

import Foundation

struct SortSection: Identifiable, Equatable, Sendable {

    /// What a change names a section by, and what the screen keys its rows on.
    ///
    /// A draft carries a `draft:`-prefixed client id (`SortDraftID`), mirroring
    /// ADR 0001's `optimistic:` convention, so a placeholder can never be mistaken
    /// for a server document — which matters the moment the write plan starts
    /// deciding what to create and what to merely fill.
    enum ID: Hashable, Sendable {
        /// An étagère that exists on the server, by its `Shelf._id`.
        case shelf(String)
        /// An étagère the user has drafted on this screen, by its client id.
        case draft(String)
        /// The books that are on no étagère at all. Exactly one per projection.
        case unshelved
    }

    let id: ID

    /// The étagère's name, or `nil` for the unshelved pile — which has no name of
    /// its own. What that section is called is copy, so it lives in the string
    /// catalogue and is resolved by the view, not carried through the model.
    let name: String?

    let books: [AutoSortBook]

    /// Derived rather than stored, so the count in a header can never disagree with
    /// the rows under it.
    var bookCount: Int { books.count }

    /// The pile reads differently from an étagère — it sits last, carries no state
    /// pill, and hides the genre line — so the screen asks this rather than
    /// re-deriving it from `id` at each call site.
    var isUnshelved: Bool { id == .unshelved }
}
