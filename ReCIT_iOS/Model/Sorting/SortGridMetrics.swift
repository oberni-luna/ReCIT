//
//  SortGridMetrics.swift
//  ReCIT_iOS
//
//  Every measurement of the sorting surface, derived from the width it is given.
//
//  It is a type of its own, and pure, because this is one of the two places a visual
//  rewrite breaks in silence: a card sized for a 393 pt screen is a card that wraps to two
//  columns on a 375 pt one, and nobody notices until someone opens the app on an SE. A
//  function of one number can be asserted at four widths in three lines (`SortGridMetricsTests`).
//
//  The two column widths come from the owner's formulas, read off the mockup
//  (`Nouveau récits`, `160:6659`):
//
//  - **Étagères**: three columns, 16 pt margins and 16 pt gutters — `3W + 4×16 = width`,
//    so 112,33 on a 393 pt screen. (The mockup draws a 12 pt gutter; the code uses 16,
//    recorded as a divergence.)
//  - **Livres à ranger**: three columns *and a peek*, because the carousel scrolls
//    horizontally and a row that ends flush at the edge looks finished. 16 pt margin,
//    12 pt gutters, and 40 pt of the next card showing — so 100,33 on 393.
//
//  Cover art reserves a **2:3 frame before its image exists**. Neither Nuke nor `Edition`
//  knows an image's ratio until the bytes arrive, so a pile of five would re-lay itself out
//  five times while the grid scrolls. A book of an unusual format is centred in its frame
//  with air around it, deliberately.
//
//  Pure by design — no SwiftUI, no device. See PRD 0009.
//

import CoreGraphics

struct SortGridMetrics: Equatable, Sendable {

    /// The gutter and margin the étagère grid is laid out on.
    static let shelfSpacing: CGFloat = 16
    /// The gutter between two book cards, and the screen margin the carousel starts at.
    static let bookSpacing: CGFloat = 12
    /// How much of the fourth book card shows past the third. It is the only thing on the
    /// carousel that says "this scrolls", so it is a measurement rather than a leftover.
    static let bookPeek: CGFloat = 40
    /// How many columns the design lays the grid on when the collection fills it.
    static let columnCount: Int = 3

    /// Above how many étagères the grid uses its full three columns.
    static let narrowGridThreshold: Int = 2
    /// A card's total height: the art, then one or two lines of title.
    static let cardHeight: CGFloat = 158
    /// The share of a card's height its art occupies, the rest being the title.
    static let artHeight: CGFloat = 106
    /// A cover's reserved shape, before its image exists.
    static let coverAspectRatio: CGFloat = 2.0 / 3.0
    /// How many covers a pile draws at most.
    static let pileCoverLimit: Int = 5

    /// The width the surface was given.
    let containerWidth: CGFloat

    init(containerWidth: CGFloat) {
        self.containerWidth = containerWidth
    }

    /// How many columns to lay `shelfCount` étagères on. Two when there are two or fewer:
    /// three narrow cards and two empty slots read as a screen that failed to load rather than
    /// as a small collection, and the cards are the only thing on screen worth looking at.
    /// The « + » tile does not count — it is an affordance, not an étagère.
    static func columnCount(forShelfCount shelfCount: Int) -> Int {
        shelfCount <= narrowGridThreshold ? 2 : columnCount
    }

    /// One étagère card's width on a grid of `columns`: `(width − (columns + 1) × 16) / columns`.
    /// The owner's formula, generalised — at three columns it still gives 109,67 on a 393 pt
    /// screen.
    func shelfColumnWidth(columns: Int) -> CGFloat {
        let count: CGFloat = .init(max(1, columns))
        let gaps: CGFloat = (count + 1) * Self.shelfSpacing
        return max(0, (containerWidth - gaps) / count)
    }

    /// One étagère card's width on the full three-column grid.
    var shelfColumnWidth: CGFloat {
        shelfColumnWidth(columns: Self.columnCount)
    }

    /// One book card's width: one margin, three columns, **three** gutters — two between
    /// the visible cards and one before the card that peeks — and the peek itself.
    /// `(width − 16 − 3 × 12 − 40) / 3`.
    var bookColumnWidth: CGFloat {
        let columns: CGFloat = .init(Self.columnCount)
        let taken: CGFloat = Self.shelfSpacing + Self.bookSpacing * columns + Self.bookPeek
        return max(0, (containerWidth - taken) / columns)
    }

    /// A cover drawn `width` wide, in its reserved 2:3 frame.
    static func coverSize(width: CGFloat) -> CGSize {
        .init(width: width, height: width / coverAspectRatio)
    }

    /// The height the carousel claims, so the anchored panel can reserve it before the
    /// library has loaded — otherwise half the screen jumps when the first sync lands.
    var carouselHeight: CGFloat { Self.cardHeight }
}
