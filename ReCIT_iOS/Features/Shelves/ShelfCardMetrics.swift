//
//  ShelfCardMetrics.swift
//  ReCIT_iOS
//
//  Every size on a shelf card, derived from the one number the carousel decides: the card
//  width. Shared by the shelf itself and by the focus overlay that redraws it sharp above
//  the blur, so the two cannot drift apart. See ADR 0006.
//

import CoreGraphics

struct ShelfCardMetrics: Equatable {
    let width: CGFloat

    /// The plank's height, from the asset's aspect ratio.
    var plankHeight: CGFloat { width * 129.0 / 820.0 }
    /// The band the books stand in, above the plank.
    var zoneHeight: CGFloat { width * 9.0 / 16.0 }
    /// Room above the books for a grown book (×1.5) to reach into without being clipped by
    /// the carousel's scroll bounds.
    var topRoom: CGFloat { zoneHeight * 0.25 }
    /// The card proper: books and plank.
    var cardHeight: CGFloat { zoneHeight + plankHeight }
    /// Width the books lay out in — the card minus a margin on each side.
    var booksWidth: CGFloat { max(width - Self.horizontalMargin * 2, 0) }

    /// Horizontal inset so the outermost books sit on the plank rather than at the very
    /// edge of the card.
    static let horizontalMargin: CGFloat = 24

    /// The share of the screen a carousel card takes, so the next one peeks.
    static let carouselShare: CGFloat = 0.86
    /// The widest a carousel card grows: what the widest phone draws (0,86 × 430). Every size
    /// above follows the width, so without a ceiling an unfolded iPhone Duo drew one étagère
    /// over most of the screen — and, in landscape, a lone book some 400 pt tall.
    static let maxCarouselCardWidth: CGFloat = 370

    /// The card width the carousel gives a container `containerWidth` wide: its share, up to
    /// the ceiling. A wider screen shows more étagères side by side rather than bigger ones.
    static func carouselCardWidth(containerWidth: CGFloat) -> CGFloat {
        min(containerWidth * carouselShare, maxCarouselCardWidth)
    }

    /// Where a finger still counts as being on this étagère: the books, the plank, and the
    /// room above where a grown book reaches. In the card's own coordinates.
    var touchBox: CGRect {
        .init(x: 0, y: -topRoom, width: width, height: topRoom + cardHeight)
    }
}
