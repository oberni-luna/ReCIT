//
//  ShelfEmptyStateErrand.swift
//  ReCIT_iOS
//
//  What the empty shelf asks for. The card has two possible errands, and this type is the
//  single place where the state picks one: the sentence above the plank and the tags resting
//  on it both come from the same value, so the two cannot drift apart.
//
//  With nothing in the inventory there is nothing to arrange, so the useful next thing is
//  filling the inventory, and there are two ways to do it: scanning the books in hand, or
//  looking up the ones that are not. With books owned but no étagère to put them on, the
//  useful next thing is the one the card has carried since PRD 0006 — arranging them, in the
//  sorting surface.
//
//  Each tag is a `ShelfEmptyStateAction`, which holds its own wording; the destinations live
//  in `ShelvesContent`, which switches over the action exactly once. See PRD 0007 for the
//  errand, and docs/features/0021 for the sentence and the tags.
//

import Foundation

/// The one errand the empty-shelf card is asking for, derived from the inventory it stands over.
enum ShelfEmptyStateErrand {
    /// The inventory is empty: fill it, by scanning or by searching.
    case scan
    /// Books are owned and none of them is on an étagère: arrange them.
    case sort

    /// The card only ever appears when the user has no étagère, so owning books is the whole
    /// question: no books means there is nothing to arrange yet.
    init(ownsBooks: Bool) {
        self = ownsBooks ? .sort : .scan
    }

    /// The step the user is at, set above the plank.
    var heading: LocalizedStringResource {
        switch self {
        case .scan:
            "shelf.empty.scan.heading"
        case .sort:
            "shelf.empty.sort.heading"
        }
    }

    /// One sentence under the heading, saying what the tags below are for.
    var body: LocalizedStringResource {
        switch self {
        case .scan:
            "shelf.empty.scan.body"
        case .sort:
            "shelf.empty.sort.body"
        }
    }

    /// The tags resting on the plank, left to right.
    var actions: [ShelfEmptyStateAction] {
        switch self {
        case .scan:
            [.scan, .search]
        case .sort:
            [.sort]
        }
    }
}
