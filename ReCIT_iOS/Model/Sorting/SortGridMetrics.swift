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

import Foundation

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
    /// The share of an étagère card's height its pile occupies, the rest being the title.
    static let artHeight: CGFloat = 106
    /// The same for a book card, whose title is a 17 pt face over two lines and therefore
    /// taller than an étagère's (`160:6659`).
    static let bookArtHeight: CGFloat = 100
    /// A cover's reserved shape, before its image exists.
    static let coverAspectRatio: CGFloat = 2.0 / 3.0
    /// How many covers a pile draws at most.
    static let pileCoverLimit: Int = 5

    /// How far apart two ranks of the fan sit, as a share of the card's width.
    static let pileFanStep: CGFloat = 0.075
    /// What share of that step is vertical. The fan opens sideways and leans *down* only.
    static let pileFanVerticalShare: CGFloat = 0.5
    /// A piled cover's width, as a share of the card's.
    static let pileCoverWidthShare: CGFloat = 0.46
    /// The same for the one cover of an étagère holding a single book, drawn face-on.
    static let singleCoverWidthShare: CGFloat = 0.52

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

    // MARK: - The pile's geometry
    //
    // A pile is not just its front cover: the ranks behind it step *downwards*, and every
    // cover leans. Sized on the front cover alone, a full fan on a two-column grid ran some
    // 25 pt past the art band and painted over the card's title. The three functions below
    // are what keeps it inside, and they are here rather than in the view because the
    // clamp they compute is a formula worth asserting at several widths.

    /// How far the deepest rank of a full fan sits below the front cover.
    ///
    /// Ranks pair up — two covers per rank, one each side — so a pile of `pileCoverLimit`
    /// reaches rank `pileCoverLimit / 2`.
    static func pileFanDrop(width: CGFloat) -> CGFloat {
        let deepestRank: CGFloat = .init(pileCoverLimit / 2)
        return deepestRank * width * pileFanStep * pileFanVerticalShare
    }

    /// How far up the whole fan is drawn, so what it occupies is centred in the art band
    /// rather than hanging off the bottom of it.
    ///
    /// Half the drop: the fan then reaches as far above the front cover as below it. Without
    /// this the band's top half goes unused and the covers have to be shrunk twice as hard to
    /// fit — 67 pt instead of 80 on a two-column grid.
    static func pileVerticalInset(width: CGFloat) -> CGFloat {
        pileFanDrop(width: width) / 2
    }

    /// One cover's frame on a card `width` wide, clamped so the fan — its drop and its lean
    /// included — stays inside `artHeight`.
    ///
    /// A cover leaning by `θ` claims `w·sin θ + h·cos θ` of height, so the tallest that still
    /// fits under `artHeight − drop` is `(artHeight − drop − w·sin θ) / cos θ`. Below that
    /// bound the book keeps its own 2:3 proportions; above it, it is the height that gives.
    static func pileCoverSize(width: CGFloat, isSingleCover: Bool) -> CGSize {
        let coverWidth: CGFloat = width * (isSingleCover ? singleCoverWidthShare : pileCoverWidthShare)
        // One cover fans nowhere, but it leans like any other.
        let drop: CGFloat = isSingleCover ? 0 : pileFanDrop(width: width)
        let tilt: CGFloat = .init(SortPile.tiltAmplitude * .pi / 180)
        let leanWidth: CGFloat = coverWidth * sin(tilt)
        let available: CGFloat = max(0, artHeight - drop - leanWidth)
        return .init(
            width: coverWidth,
            height: min(coverWidth / coverAspectRatio, available / cos(tilt))
        )
    }

    /// The height the carousel claims, so the anchored panel can reserve it before the
    /// library has loaded — otherwise half the screen jumps when the first sync lands.
    var carouselHeight: CGFloat { Self.cardHeight }
}
