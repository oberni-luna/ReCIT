//
//  SortChange.swift
//  ReCIT_iOS
//
//  One entry of the sorting session's change stack. Two cases suffice for everything
//  the screen can do: bring an étagère into existence, and move a book from one
//  section to another.
//
//  **The working state is a stack, not a mutable target state.** Both derivations the
//  screen depends on — the projection it renders, and the write plan it will execute
//  (slice 0040) — are pure functions of the snapshot and this stack, which is what
//  lets a pill, a recap and a write agree by construction rather than by care.
//
//  A move carries its **origin** as well as its destination even though the
//  projection only needs the destination. Coalescing needs it — a book taken off a
//  shelf and put back must reduce to nothing — and so would any future undo. Deriving
//  the origin from a re-run of the projection would make the reduction depend on the
//  snapshot, which is exactly the coupling the stack exists to avoid.
//
//  Pure by design — no store, no SwiftUI. See PRD 0008.
//

import Foundation

enum SortChange: Equatable, Sendable {

    /// A new étagère, named but not yet written. `draftId` is a `SortDraftID`.
    case createShelf(draftId: String, name: String)

    /// A book leaves one section for another. `bookId` is the item's server `_id`.
    case moveBook(bookId: String, from: SortSection.ID, to: SortSection.ID)
}

extension SortChange {

    /// One drop, as a change — or nothing at all when the book is dropped back on the
    /// section it was dragged from.
    ///
    /// The no-op belongs here rather than in the session model because it is a rule
    /// about the stack, and the stack is what the button labels are derived from: a
    /// change that changes nothing would still make the apply button live and turn
    /// « Terminer » into « Annuler », so the screen would be offering to discard work
    /// that does not exist. Pure, so it is assertable without a view or a gesture.
    static func move(
        bookId: String,
        from origin: SortSection.ID,
        to destination: SortSection.ID
    ) -> SortChange? {
        guard origin != destination else { return nil }
        return .moveBook(bookId: bookId, from: origin, to: destination)
    }
}
