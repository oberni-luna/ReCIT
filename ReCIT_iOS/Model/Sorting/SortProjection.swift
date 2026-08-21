//
//  SortProjection.swift
//  ReCIT_iOS
//
//  Snapshot + change stack → the sections the sorting screen renders. One of the two
//  derivations PRD 0008 rests on, and the one the user actually looks at.
//
//  **It owns one invariant: every book sits in exactly one section.** A drop removes
//  before it adds, which here is not a sequence of two steps but a single assignment
//  in a book → section map — the cheapest possible way to make the rule
//  unbreakable. The same partition rule the auto-sort plan keeps by filing a
//  multi-genre book under its first genre (`AutoSortBook.primaryGenre`), and for the
//  same reason: a book in two sections would be written twice.
//
//  The store does not hand us a partition. `Shelf ⇄ InventoryItem` is many-to-many
//  and a copy may sit on several étagères (ADR 0003), so the first étagère that
//  claims a book keeps it and the later ones simply do not list it. First rather
//  than last so the reading is stable under a reordering of the change stack, and
//  first rather than "duplicate it" because duplicating is precisely what makes a
//  book get written twice.
//
//  **`displayOrder` is how the screen stays smooth, and it writes nothing.** The list's
//  own reorder is positional: it animates the row to the exact slot the finger dropped it
//  in. Membership, though, carries no user-facing order (PRD 0008), so any order this type
//  invented — snapshot order, arrival order — was a *different* arrangement from the one
//  just animated, and SwiftUI animated the difference on top. That is what made a dropped
//  row sit over the row it landed on for half a second.
//
//  So the caller hands in the order it wants, and the screen hands in precisely the
//  permutation the list performed. Nothing is derived twice and nothing disagrees. It is
//  display only — `SortWritePlan` builds its projections without it, so what gets written
//  cannot depend on it — and it is not persisted: reopening the screen re-freezes.
//
//  Recomputed rather than tracked. It is cheap, and a tracked target state is how a
//  pill, a recap and a write end up disagreeing.
//
//  Pure by design — no store, no network, no SwiftUI. See PRD 0008.
//

import Foundation

struct SortProjection: Equatable, Sendable {

    /// Every étagère in snapshot order, then every draft in the order it was
    /// created, then the unshelved pile — always last, and always present, because
    /// it is a drop target whether or not it holds anything today.
    let sections: [SortSection]

    init(
        snapshot: SortSnapshot,
        changes: [SortChange] = [],
        displayOrder: [String] = []
    ) {
        // Books keyed by id, first occurrence winning, so a store that somehow held
        // two rows for one `_id` still yields one book on screen.
        var booksById: [String: AutoSortBook] = [:]
        var bookOrder: [String] = []
        for book in snapshot.books where booksById[book.id] == nil {
            booksById[book.id] = book
            bookOrder.append(book.id)
        }

        // The sections, in reading order. Names are kept beside the ids rather than
        // looked up later, so a draft named by the stack and an étagère named by the
        // snapshot are resolved in exactly one place.
        var sectionIds: [SortSection.ID] = snapshot.shelves.map { .shelf($0.id) }
        var namesById: [SortSection.ID: String] = [:]
        for shelf in snapshot.shelves {
            namesById[.shelf(shelf.id)] = shelf.name
        }

        // Where each book sits. Assignment, never insertion, is what enforces the
        // invariant: a book cannot be in two places because it has one entry.
        var sectionOfBook: [String: SortSection.ID] = [:]
        for shelf in snapshot.shelves {
            for bookId in shelf.bookIds where booksById[bookId] != nil && sectionOfBook[bookId] == nil {
                sectionOfBook[bookId] = .shelf(shelf.id)
            }
        }

        // Where each book sits *within* its section. A book named by `displayOrder` takes
        // its place there; anything the caller did not mention keeps its snapshot position,
        // after them, so a partial order is still a total one.
        var rankOfBook: [String: Int] = [:]
        for (offset, bookId) in bookOrder.enumerated() {
            rankOfBook[bookId] = displayOrder.count + offset
        }
        for (offset, bookId) in displayOrder.enumerated() {
            rankOfBook[bookId] = offset
        }

        for change in changes {
            switch change {
            case .createShelf(let draftId, let name):
                let id: SortSection.ID = .draft(draftId)
                // A second creation under the same id renames rather than adding a
                // twin, so the stack cannot put two sections on screen for one draft.
                if namesById[id] == nil {
                    sectionIds.append(id)
                }
                namesById[id] = name

            case .moveBook(let bookId, _, let destination):
                // A move naming a book or a section the projection does not know is
                // ignored rather than trapped: the stack outlives nothing here, but
                // an apply that rebuilds the snapshot partway (slice 0040) can leave
                // a change referring to something that has since landed, and the
                // screen must keep rendering.
                guard booksById[bookId] != nil else { continue }
                guard destination == .unshelved || namesById[destination] != nil else { continue }
                sectionOfBook[bookId] = destination
            }
        }

        sectionIds.append(.unshelved)

        var booksBySection: [SortSection.ID: [AutoSortBook]] = [:]
        for bookId in bookOrder.sorted(by: { rankOfBook[$0, default: .max] < rankOfBook[$1, default: .max] }) {
            guard let book = booksById[bookId] else { continue }
            let section: SortSection.ID = sectionOfBook[bookId] ?? .unshelved
            booksBySection[section, default: []].append(book)
        }

        sections = sectionIds.map { id in
            .init(
                id: id,
                name: id == .unshelved ? nil : namesById[id],
                books: booksBySection[id] ?? []
            )
        }
    }

    /// The pile, which every projection has. Convenient for the screen and for a
    /// test that wants to state something about the books nobody has filed.
    var unshelved: SortSection {
        sections.first { $0.isUnshelved } ?? .init(id: .unshelved, name: nil, books: [])
    }
}
