//
//  ShelfEmptyStateErrand.swift
//  ReCIT_iOS
//
//  What the note on the empty plank asks for. The card has two possible errands, and this
//  type is the single place where the state picks one: the note's wording and the press's
//  destination both come from the same value, so the two cannot drift apart. A card that
//  opens something other than what its label promises is the failure this type exists to
//  make impossible.
//
//  With nothing in the inventory there is nothing to arrange, so the useful next thing is
//  filling the inventory: the note reads *Scanner mes livres* and the press opens the batch
//  scanner. With books owned but no étagère to put them on, the useful next thing is the one
//  the card has carried since PRD 0006 — *Ranger mes livres*, into automatic shelving.
//
//  Only the wording lives here. The destinations do not: one is a full-screen cover and the
//  other a push onto the tab's path, and neither is a value this type could hold.
//  `ShelvesContent` switches over the errand exactly once to open the right one. See PRD 0007.
//

import Foundation

/// The one errand the empty-shelf card is asking for, derived from the inventory it stands over.
enum ShelfEmptyStateErrand {
    /// The inventory is empty: fill it, with the batch scanner.
    case scan
    /// Books are owned and none of them is on an étagère: arrange them, with automatic shelving.
    case sort

    /// The card only ever appears when the user has no étagère, so owning books is the whole
    /// question: no books means there is nothing to arrange yet.
    init(ownsBooks: Bool) {
        self = ownsBooks ? .sort : .scan
    }

    /// The note's two lines — a *Todo* heading and the one thing to do — as `ShelfLabelView`
    /// paints them. Resolved here rather than in the view because the view takes a plain
    /// `String`, and because the wording has to be decided in the same breath as the destination.
    var noteText: String {
        switch self {
        case .scan:
            String(localized: "shelf.empty.note.scan")
        case .sort:
            String(localized: "shelf.empty.note.sort")
        }
    }
}
