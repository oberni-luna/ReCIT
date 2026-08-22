//
//  SortPile.swift
//  ReCIT_iOS
//
//  What one étagère's card draws: the first few books of the shelf, laid one over another,
//  each leaning a little — and, crucially, **which one of them is the book the card hands
//  over when it is dragged**.
//
//  That last sentence is why this is a type and not a `ForEach` inside a view. The card's
//  drag source is a single cover (PRD 0009), so position and rank have to agree: the book
//  the user grabs must be the book they see on top. Written in a view, that correspondence
//  is a detail of a layout nobody can assert; written here, it is one line of a test.
//
//  **The top of the pile is the front of the pile is the first of the section.** A
//  section's books arrive already ordered by `SortProjection`, most recently filed first,
//  so `covers.first` is both the visual front and the draggable book, and a mis-drop is
//  undone by dragging back what was just dropped.
//
//  Depth runs the other way — the last cover is drawn first, the front one last — so a
//  view renders `covers.reversed()` and finishes with the one it will make draggable.
//
//  Tilt is derived from each book's title through `DeterministicTilt`, so a shelf leans the
//  same way on every launch and two books never share an angle by accident. ±10°: enough to
//  read as a handled pile, little enough that a cover stays a cover.
//
//  Pure by design — no SwiftUI, no store. See PRD 0009.
//

import Foundation

struct SortPile: Equatable, Sendable {

    /// The widest a piled cover leans, either way.
    static let tiltAmplitude: Double = 10

    /// One cover of the pile.
    struct Cover: Identifiable, Equatable, Sendable {
        let book: AutoSortBook
        /// 0 for the front cover, growing towards the back.
        let depth: Int
        /// This cover's lean, in degrees, derived from the book's title.
        let tiltDegrees: Double

        var id: String { book.id }
    }

    /// The covers to draw, front first. Empty for an étagère holding nothing — which is a
    /// normal state, not an error: it is what a draft looks like for as long as it takes to
    /// drop the first book on it.
    let covers: [Cover]

    /// How many books the étagère holds in total, which is what the card's title says. Kept
    /// beside the covers rather than derived from them, since the pile shows at most five.
    let bookCount: Int

    init(books: [AutoSortBook], limit: Int = SortGridMetrics.pileCoverLimit) {
        bookCount = books.count
        covers = books.prefix(max(0, limit)).enumerated().map { offset, book in
            .init(
                book: book,
                depth: offset,
                tiltDegrees: DeterministicTilt.degrees(for: book.title, amplitude: Self.tiltAmplitude)
            )
        }
    }

    init(section: SortSection) {
        self.init(books: section.books)
    }

    /// The book a drag from this card carries — the front cover's, or `nil` for an empty
    /// étagère, which is a drop target and nothing else.
    var draggableBook: AutoSortBook? { covers.first?.book }

    /// Whether the card draws a single cover face-on rather than a pile. One book is not a
    /// pile of one: it is a book, and the design shows it plainly.
    var isSingleCover: Bool { covers.count == 1 }

    var isEmpty: Bool { covers.isEmpty }
}
