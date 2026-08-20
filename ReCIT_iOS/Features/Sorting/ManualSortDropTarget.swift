//
//  ManualSortDropTarget.swift
//  ReCIT_iOS
//
//  Which of the surface's drop destinations the finger is currently over.
//
//  A section is highlighted as a whole, but a `List` gives nothing to hang a single
//  destination on for a whole section — so every row carries one, all naming the same
//  section. That makes the *slot* part of the identity necessary rather than
//  decorative: crossing from one row to the next fires the new row's
//  `isTargeted(true)` and the old row's `isTargeted(false)` in an order nobody
//  promises, and a highlight tracked by section alone would be switched off by the row
//  being left. Tracked by slot, the row being left can check that it is still the one
//  holding the highlight before clearing it, and both orders end up right.
//
//  See PRD 0008.
//

import Foundation

struct ManualSortDropTarget: Hashable {

    /// The part of a section that received the drag. A section shows either its books
    /// or its empty-state note, never both, so `header` and one of the other two are
    /// all that can coexist — and they are distinct.
    enum Slot: Hashable {
        case header
        case placeholder
        case book(String)
    }

    let section: SortSection.ID
    let slot: Slot
}
