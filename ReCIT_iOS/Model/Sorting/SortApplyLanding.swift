//
//  SortApplyLanding.swift
//  ReCIT_iOS
//
//  One operation the server confirmed, folded back into the session: the snapshot
//  gains what landed, and the stack is left holding exactly the work that is still to
//  do.
//
//  **This is what makes a failure halfway survivable.** The apply stops where it broke
//  and nothing is rolled back, so the only honest thing to keep on screen is the
//  remainder — and the remainder has to be *in the stack*, because the stack is what
//  the pills, the recap and the button labels are derived from (PRD 0008). Trim it as
//  the run goes and every one of those goes on telling the truth with no special case:
//  an étagère that landed loses its pill because there is nothing left to write to it,
//  and pressing « Appliquer le rangement » again sends the rest.
//
//  **Re-sending the whole stack would be wrong.** `add-items` drops the items a shelf
//  already holds, so it is idempotent; a *creation* is not — replaying one that
//  succeeded makes a second étagère of the same name. So a creation leaves the stack
//  the instant the server confirms it, even when the membership write that follows it
//  in the same group fails: what is left in the stack for that étagère is then a plain
//  fill of a shelf that now exists.
//
//  **The reduction is stateless: the stack *is* the target.** `projection(snapshot,
//  changes)` is where the user means their library to end up, so the rebuilt stack is
//  simply the difference between the snapshot the confirmation just updated and that
//  same target — with a created draft's section swapped for the étagère the server
//  gave it. Nothing has to be carried between landings, which is why this is a value
//  and not a piece of the session model's state.
//
//  One rule is worth stating: **a draft that ends up holding nothing disappears from
//  the rebuilt stack.** It was never going to be created (`SortWritePlan` drops it and
//  the recap names it), so keeping it would leave the stack non-empty after a
//  successful apply — which would leave the screen offering to save work that does not
//  exist, and its only destructive button labelled « Annuler » forever.
//
//  Pure by design — no store, no network, no SwiftUI. See PRD 0008.
//

import Foundation

struct SortApplyLanding: Equatable, Sendable {

    /// What the server said it did. One per call actually made, not one per étagère:
    /// a group is create-then-remove-then-add, and each of the three lands on its own
    /// so a failure at the second step still keeps the first out of the stack.
    enum Confirmation: Equatable, Sendable {
        /// A drafted étagère now exists, under the id the server assigned it.
        case shelfCreated(draftId: String, shelfId: String, name: String)
        /// Books that are no longer on this étagère.
        case booksRemoved(shelfId: String, bookIds: [String])
        /// Books that are now on this étagère.
        case booksAdded(shelfId: String, bookIds: [String])
    }

    /// The library as the server now holds it, as far as this run knows.
    let snapshot: SortSnapshot

    /// Exactly the work that is left. Empty once everything has landed.
    let changes: [SortChange]

    init(
        snapshot: SortSnapshot,
        changes: [SortChange],
        confirmed: Confirmation
    ) {
        // Where the user means every book to end up, and which drafts are still owed
        // an étagère. Read off the projection rather than off the stack, so the rule
        // that a book sits in exactly one section is the same one the screen renders.
        let target: SortProjection = .init(snapshot: snapshot, changes: changes)

        var destination: [String: SortSection.ID] = [:]
        var pendingDrafts: [(id: String, name: String)] = []
        for section in target.sections where section.isUnshelved == false {
            for book in section.books {
                destination[book.id] = section.id
            }
            if case .draft(let draftId) = section.id {
                pendingDrafts.append((draftId, section.name ?? ""))
            }
        }

        var shelves: [SortSnapshot.Shelf] = snapshot.shelves

        switch confirmed {
        case .shelfCreated(let draftId, let shelfId, let name):
            // Appended rather than slotted into name order: the draft was the last
            // section before « À ranger » and the étagère it became stays there, so
            // nothing jumps around the screen while the run is going.
            if shelves.contains(where: { $0.id == shelfId }) == false {
                shelves.append(.init(id: shelfId, name: name, bookIds: []))
            }
            for (bookId, section) in destination where section == .draft(draftId) {
                destination[bookId] = .shelf(shelfId)
            }
            pendingDrafts.removeAll { $0.id == draftId }

        case .booksRemoved(let shelfId, let bookIds):
            let removed: Set<String> = .init(bookIds)
            shelves = shelves.map { shelf in
                guard shelf.id == shelfId else { return shelf }
                return .init(
                    id: shelf.id,
                    name: shelf.name,
                    bookIds: shelf.bookIds.filter { removed.contains($0) == false }
                )
            }

        case .booksAdded(let shelfId, let bookIds):
            shelves = shelves.map { shelf in
                guard shelf.id == shelfId else { return shelf }
                let held: Set<String> = .init(shelf.bookIds)
                return .init(
                    id: shelf.id,
                    name: shelf.name,
                    bookIds: shelf.bookIds + bookIds.filter { held.contains($0) == false }
                )
            }
        }

        let landed: SortSnapshot = .init(shelves: shelves, books: snapshot.books)
        let library: SortProjection = .init(snapshot: landed)

        var current: [String: SortSection.ID] = [:]
        for section in library.sections where section.isUnshelved == false {
            for book in section.books {
                current[book.id] = section.id
            }
        }

        // Creations first: the projection ignores a move naming a section it does not
        // know, so a stack that filled a draft before declaring it would lose its books.
        var rebuilt: [SortChange] = []
        for draft in pendingDrafts where destination.values.contains(.draft(draft.id)) {
            rebuilt.append(.createShelf(draftId: draft.id, name: draft.name))
        }
        for book in library.sections.flatMap(\.books) {
            let origin: SortSection.ID = current[book.id] ?? .unshelved
            let wanted: SortSection.ID = destination[book.id] ?? .unshelved
            guard origin != wanted else { continue }
            rebuilt.append(.moveBook(bookId: book.id, from: origin, to: wanted))
        }

        self.snapshot = landed
        self.changes = rebuilt
    }
}
