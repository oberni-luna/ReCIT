//
//  SortPileView.swift
//  ReCIT_iOS
//
//  The art on an étagère's card: the shelf's first few books, laid one over another and each
//  leaning a little, drawn back to front so the top of the pile is the last thing painted and
//  the first thing the eye — and the finger — finds.
//
//  What is drawn, in what order, and at what angle is `SortPile`'s answer, not this view's.
//  That separation is the point: the card hands one cover to the drag (PRD 0009), so the
//  correspondence between "the cover in front" and "the book that travels" has to be
//  assertable without a rendering. Here there is only geometry.
//
//  Three states, because a shelf is not always a pile: nothing at all for an étagère that
//  holds none — which is the normal state of a draft, and a drop target rather than an
//  error; one cover face-on for a shelf of one, since a pile of one is just a book; and the
//  fan for anything above that.
//
//  Every cover reserves a 2:3 frame before its image exists (`SortGridMetrics`), so a pile
//  does not re-lay itself out five times while the grid scrolls.
//

import SwiftUI

struct SortPileView: View {
    let pile: SortPile
    /// The card's width. Every measurement here is a share of it.
    let width: CGFloat

    var body: some View {
        ZStack {
            if pile.isEmpty {
                SortEmptyPileView(width: width)
            } else {
                // Back to front: the last cover is painted first, so the front cover — the
                // one a drag carries — ends up on top without a z-index to maintain.
                ForEach(pile.covers.reversed()) { cover in
                    ShelfCoverView(
                        imageUrl: cover.book.coverImageUrl,
                        title: cover.book.title,
                        size: coverSize
                    )
                    .rotationEffect(.degrees(cover.tiltDegrees))
                    .offset(offset(for: cover))
                }
            }
        }
        .frame(width: width, height: SortGridMetrics.artHeight)
    }

    /// One cover's frame. Narrow enough that a fan of five still shows five spines' worth of
    /// colour, tall enough to keep the book's own proportions.
    private var coverSize: CGSize {
        let coverWidth: CGFloat = pile.isSingleCover ? width * 0.52 : width * 0.46
        return .init(
            width: coverWidth,
            height: min(SortGridMetrics.artHeight, coverWidth / SortGridMetrics.coverAspectRatio)
        )
    }

    /// Where a cover sits relative to the middle of the card. The fan opens right and down
    /// as it goes back, so each cover's spine edge stays visible and the front one is the
    /// one nearest the reader — which is what makes "grab the top book" mean anything.
    private func offset(for cover: SortPile.Cover) -> CGSize {
        guard pile.isSingleCover == false else { return .zero }
        let step: CGFloat = width * 0.075
        let depth: CGFloat = .init(cover.depth)
        return .init(
            width: depth * step - step,
            height: depth * step * 0.5 - step * 0.5
        )
    }
}

/// An étagère holding nothing: a cover-shaped hole, dashed, the same size as the card's art.
/// A drop target that has the shape of a full one is more legible than an illustration —
/// what it says is "the book goes here".
struct SortEmptyPileView: View {
    let width: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: .minimal)
            .strokeBorder(
                DesignSystem.Color.borderDefault.color,
                style: .init(lineWidth: 1, dash: [4, 4])
            )
            .frame(
                width: width * 0.46,
                height: min(SortGridMetrics.artHeight, width * 0.46 / SortGridMetrics.coverAspectRatio)
            )
    }
}
