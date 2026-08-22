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
//  **Order inside a section is arrival order, and it is derived — not carried.** The books
//  this session moved into a section come first, the most recent move first; behind them,
//  the books that were already there, in snapshot order (inventory `created` desc).
//
//  That rule is what makes the sorting surface's piles work (PRD 0009): the front of a pile
//  is the book just filed, and the front of the pile is what a drag from the card carries —
//  so a mis-drop is undone by dragging back exactly what was dropped. It replaces
//  `displayOrder`, which existed only to hand the old `List` the permutation its edit-mode
//  reorder had just performed. There is no list any more, and nothing positional to mirror:
//  the order is a function of `(snapshot, changes)` like everything else here, so it cannot
//  drift from the stack and nothing has to be reset when an apply lands.
//
//  Recomputed rather than tracked. It is cheap, and a tracked target state is how a
//  pill, a recap and a write end up disagreeing. The **caller** must read it once per render
//  and pass value types down, though: a card reading it in its own body would pay a walk
//  over the whole library per card per animation frame.
//
//  Pure by design — no store, no network, no SwiftUI. See PRD 0008 and PRD 0009.
//

import Foundation

struct SortProjection: Equatable, Sendable {

    /// Every étagère in snapshot order, then every draft in the order it was
    /// created, then the unshelved pile — always last, and always present, because
    /// it is a drop target whether or not it holds anything today.
    let sections: [SortSection]

    init(
        snapshot: SortSnapshot,
        changes: [SortChange] = []
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

        // When this session filed each book where it now sits. Overwritten with every
        // move, so a book moved three times carries the index of its last move only —
        // the one that decided where it is.
        var arrivalOfBook: [String: Int] = [:]

        for (index, change) in changes.enumerated() {
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
                // an apply that rebuilds the snapshot partway can leave a change
                // referring to something that has since landed, and the screen must
                // keep rendering.
                guard booksById[bookId] != nil else { continue }
                guard destination == .unshelved || namesById[destination] != nil else { continue }
                sectionOfBook[bookId] = destination
                arrivalOfBook[bookId] = index
            }
        }

        sectionIds.append(.unshelved)

        var booksBySection: [SortSection.ID: [AutoSortBook]] = [:]
        for bookId in bookOrder {
            guard let book = booksById[bookId] else { continue }
            let section: SortSection.ID = sectionOfBook[bookId] ?? .unshelved
            booksBySection[section, default: []].append(book)
        }

        sections = sectionIds.map { id in
            let books: [AutoSortBook] = Self.inArrivalOrder(
                booksBySection[id] ?? [],
                arrivals: arrivalOfBook
            )
            return .init(
                id: id,
                name: id == .unshelved ? nil : namesById[id],
                books: books
            )
        }
    }

    /// One section's books, arrivals first. A stable partition rather than a sort over a
    /// mixed key: the books this session moved here keep their relative order by *when*
    /// they arrived (latest first), and everything else keeps snapshot order behind them.
    private static func inArrivalOrder(
        _ books: [AutoSortBook],
        arrivals: [String: Int]
    ) -> [AutoSortBook] {
        var arrived: [AutoSortBook] = []
        var settled: [AutoSortBook] = []
        for book in books {
            if arrivals[book.id] == nil {
                settled.append(book)
            } else {
                arrived.append(book)
            }
        }
        arrived.sort { arrivals[$0.id, default: .min] > arrivals[$1.id, default: .min] }
        return arrived + settled
    }

    /// The pile, which every projection has. Convenient for the screen and for a
    /// test that wants to state something about the books nobody has filed.
    var unshelved: SortSection {
        sections.first { $0.isUnshelved } ?? .init(id: .unshelved, name: nil, books: [])
    }
}
