//
//  ManualSortRows.swift
//  ReCIT_iOS
//
//  The sorting surface flattened into one list of rows, and the rule that says which
//  étagère a row dropped at a given index has landed in.
//
//  **Why one flat list rather than one `Section` per étagère.** Moving a book has to
//  cross étagères, and SwiftUI's edit-mode reorder only ever moves a row inside the
//  `ForEach` it belongs to — a `Section` per étagère therefore makes the one gesture the
//  feature exists for impossible. Flattening headers and books into a single `ForEach`
//  buys the native gesture: the system's own grip, its own lift, its own animation, and
//  a drop that cannot fail. What it costs is the card per étagère, which `Section` was
//  drawing for free; `isCardTop` / `isCardBottom` hand that back to the view, which
//  paints it per row.
//
//  A header is a row like any other, but not a movable one — see `isMovable`. The pile
//  is a section like any other here, which is what lets a book be dragged out of an
//  étagère and back.
//
//  Pure by design — no store, no SwiftUI, so the destination rule is asserted as a
//  sentence rather than exercised through a gesture. See PRD 0008.
//

import Foundation

struct ManualSortRow: Identifiable, Equatable, Sendable {

    enum Content: Equatable, Sendable {
        /// The band's name, count, pill and mark. Carries the whole section because the
        /// header view reads all of it.
        case header(SortSection)
        case book(AutoSortBook)
        /// An étagère with nothing under it. It still occupies a row, because a section
        /// with no rows is a drop target no finger can reach — and a book dragged out of
        /// an étagère could then never be put back, so the gesture would stop being its
        /// own inverse.
        ///
        /// It has to be **movable**, too. See `isMovable`.
        case empty
    }

    /// The section this row belongs to — for a book, the section it would be leaving.
    let section: SortSection.ID

    let content: Content

    /// Whether this row draws the top, respectively the bottom, of its étagère's card.
    /// A single-row group is both.
    let isCardTop: Bool
    let isCardBottom: Bool

    var id: String {
        switch content {
        case .header: "header-\(sectionKey)"
        case .book(let book): "book-\(book.id)"
        case .empty: "empty-\(sectionKey)"
        }
    }

    /// Books move, and so does the placeholder of an empty étagère — headers do not.
    ///
    /// A header dragged anywhere would be asking to reorder the étagères, which PRD 0008
    /// puts out of scope. The placeholder is a different matter: **edit-mode reorder can
    /// only drop a row at an index a movable row occupies**, so a run of immovable rows
    /// offers no slot to aim at. An étagère holding nothing therefore had exactly one row,
    /// immovable, and could not be filled at all — neither a freshly created one nor
    /// « À ranger » once every book had been filed, which is precisely the étagère a user
    /// most wants to drop into.
    ///
    /// Making it movable costs one oddity: the placeholder can be picked up. Nothing comes
    /// of it — `book(at:)` finds no book, so no change is pushed — and it buys back the
    /// only drop target the empty section has.
    var isMovable: Bool {
        switch content {
        case .header: false
        case .book, .empty: true
        }
    }

    private var sectionKey: String {
        switch section {
        case .shelf(let id): "shelf-\(id)"
        case .draft(let id): "draft-\(id)"
        case .unshelved: "unshelved"
        }
    }
}

struct ManualSortRows: Equatable, Sendable {

    let rows: [ManualSortRow]

    init(sections: [SortSection]) {
        var rows: [ManualSortRow] = []

        for section in sections {
            rows.append(
                .init(
                    section: section.id,
                    content: .header(section),
                    isCardTop: false,
                    isCardBottom: false
                )
            )

            if section.books.isEmpty {
                rows.append(
                    .init(
                        section: section.id,
                        content: .empty,
                        isCardTop: true,
                        isCardBottom: true
                    )
                )
            } else {
                for (offset, book) in section.books.enumerated() {
                    rows.append(
                        .init(
                            section: section.id,
                            content: .book(book),
                            isCardTop: offset == section.books.startIndex,
                            isCardBottom: offset == section.books.count - 1
                        )
                    )
                }
            }
        }

        self.rows = rows
    }

    /// The étagère a row let go of at `index` has landed in.
    ///
    /// `onMove` hands over the index the row *would be inserted at* in the list as it
    /// stands, so the section is the one owning the row just above that point. Dropping
    /// exactly onto a header therefore lands in the section above it, which is the
    /// honest reading: the finger is at the boundary, and the row above is the one it
    /// left the gap under. Above the very first header there is nothing to be above, so
    /// the first section takes it rather than the drop being refused.
    func section(forInsertionAt index: Int) -> SortSection.ID? {
        guard rows.isEmpty == false else { return nil }
        guard index > 0 else { return rows.first?.section }

        return rows[min(index, rows.count) - 1].section
    }

    /// The book at a flat index, with the section it is leaving — the two halves a move
    /// records.
    func book(at index: Int) -> (id: String, origin: SortSection.ID)? {
        guard rows.indices.contains(index) else { return nil }
        guard case .book(let book) = rows[index].content else { return nil }

        return (book.id, rows[index].section)
    }
}
