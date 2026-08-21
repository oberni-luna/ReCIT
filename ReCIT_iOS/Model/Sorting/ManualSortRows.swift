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
//  **There is no placeholder row, and that is deliberate.** An empty étagère used to get a
//  row of its own carrying « cette étagère est vide », because edit-mode reorder can only
//  drop a row where a movable row already sits. But then filling that étagère *deleted* a
//  row while the list had just performed a length-preserving move, so SwiftUI had an
//  insertion and a deletion to animate on top of the drop — the placeholder and the
//  arriving book were both on screen for a third of a second. Making the row permanent and
//  invisible does not work either: in edit mode the list reserves a grip's height for every
//  movable row, and the one shape that does collapse (`EmptyView`) leaves it unclear whether
//  `onMove`'s indices still line up with what the user can see — a risk of filing a book
//  onto the wrong shelf, which is not a trade worth making for an animation.
//
//  So an empty étagère contributes exactly one row, its header, and **that header is the
//  drop target** — see `isMovable` and `section(forInsertionAt:)`. A move then only ever
//  changes which section a book row belongs to, never how many rows there are, which is
//  precisely the operation the list animated.
//
//  Pure by design — no store, no SwiftUI, so the destination rule is asserted as a
//  sentence rather than exercised through a gesture. See PRD 0008.
//

import Foundation

struct ManualSortRow: Identifiable, Equatable, Sendable {

    enum Content: Equatable, Sendable {
        /// The band's name, count, pill and mark. Carries the whole section because the
        /// header view reads all of it — and because whether the section is empty decides
        /// whether this row is a drop target.
        case header(SortSection)
        case book(AutoSortBook)
    }

    /// The section this row belongs to — for a book, the section it would be leaving.
    let section: SortSection.ID

    let content: Content

    /// Whether this row draws the top, respectively the bottom, of its étagère's card.
    /// A lone book is both. Headers are neither: they sit on the page.
    let isCardTop: Bool
    let isCardBottom: Bool

    var id: String {
        switch content {
        case .header: "header-\(sectionKey)"
        case .book(let book): "book-\(book.id)"
        }
    }

    /// Books move. So does the header of an **empty** étagère, because it is the only row
    /// that étagère has and edit-mode reorder can only drop where a movable row sits — an
    /// étagère with no movable row cannot be filled at all, neither a freshly created one
    /// nor « À ranger » once every book has been filed.
    ///
    /// A header that has books under it stays put: dragging it would be asking to reorder
    /// the étagères, which PRD 0008 puts out of scope. Picking up an empty one does nothing
    /// either — `book(at:)` finds no book there, so no change is pushed — it exists to be
    /// aimed at, not to be carried.
    var isMovable: Bool {
        switch content {
        case .header(let section): section.books.isEmpty
        case .book: true
        }
    }

    /// Whether this row is the sole row of an étagère holding nothing.
    var isEmptySectionHeader: Bool {
        switch content {
        case .header(let section): section.books.isEmpty
        case .book: false
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

        self.rows = rows
    }

    /// The étagère a row let go of at `index` has landed in.
    ///
    /// `onMove` hands over the index the row *would be inserted at*, so ordinarily the
    /// section is the one owning the row just above that point. Dropping exactly onto a
    /// header therefore lands in the section above it: the finger is at the boundary, and
    /// the row above is the one it left the gap under.
    ///
    /// **An empty étagère's header claims that boundary instead.** Its header is the only
    /// row it has, so the gap immediately before it is the only place a finger can aim to
    /// fill it — whereas the étagère above is still reachable by dropping onto any of its
    /// books. Giving the ambiguous boundary to the empty one is what makes it fillable at
    /// all.
    ///
    /// Above the very first header there is nothing to be above, so the first section takes
    /// it rather than the drop being refused.
    func section(forInsertionAt index: Int) -> SortSection.ID? {
        guard rows.isEmpty == false else { return nil }

        let bounded: Int = min(max(index, .zero), rows.count)

        if bounded < rows.count, rows[bounded].isEmptySectionHeader {
            return rows[bounded].section
        }

        guard bounded > 0 else { return rows.first?.section }

        return rows[bounded - 1].section
    }

    /// The book at a flat index, with the section it is leaving — the two halves a move
    /// records.
    func book(at index: Int) -> (id: String, origin: SortSection.ID)? {
        guard rows.indices.contains(index) else { return nil }
        guard case .book(let book) = rows[index].content else { return nil }

        return (book.id, rows[index].section)
    }
}
