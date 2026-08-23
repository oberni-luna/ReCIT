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
//  **The front cover is the drag source**, and the only one: the rest of the card taps
//  through to the étagère's own screen. A narrow source is deliberate — it is the app's
//  existing grammar, where a *book* is pressed on a shelf and not the card around it
//  (ADR 0006) — and it is the same cover the bounce plays on, so what the user grabs is
//  what they just saw arrive.
//

import SwiftUI

struct SortPileView: View {
    let pile: SortPile
    /// The card's width. Every measurement here is a share of it.
    let width: CGFloat
    /// Whether the front cover can be dragged off. False while a run owns the stack, and on
    /// any surface that is showing a pile rather than offering to rearrange it.
    var isDraggable: Bool = true
    /// Set when this étagère has just been written, or has just received a proposal: every
    /// visible cover bounces in, one after another. Nil at rest.
    var landingToken: String?
    /// How long this pile waits before starting its pass. Non-zero when several étagères are
    /// landing together and the design wants them to arrive left to right.
    var landingDelay: Double = 0

    var body: some View {
        ZStack {
            if pile.isEmpty {
                SortEmptyPileView(width: width)
            } else {
                // Back to front: the last cover is painted first, so the front cover — the
                // one a drag carries — ends up on top without a z-index to maintain.
                ForEach(pile.covers.reversed()) { cover in
                    coverView(cover)
                }
            }
        }
        .frame(width: width, height: SortGridMetrics.artHeight)
    }

    /// One cover of the pile — and, for the front one only, the handle a drag starts from and
    /// the bounce an arrival plays on.
    private func coverView(_ cover: SortPile.Cover) -> some View {
        let isFront: Bool = cover.depth == 0

        return ShelfCoverView(
            imageUrl: cover.book.coverImageUrl,
            title: cover.book.title,
            size: coverSize
        )
        // The drag is attached **before** the tilt on purpose: `draggable` snapshots the view it
        // is attached to, and above the rotation it lifted a turned cover clipped by the card —
        // white corners and a cropped spine. Here what travels is the cover, square and whole.
        .sortBookDraggable(cover.book, isEnabled: isFront && isDraggable)
        .rotationEffect(.degrees(cover.tiltDegrees))
        .offset(offset(for: cover))
        .sortLandingBounce(bookId: isFront ? cover.book.id : nil)
        .sortStaggeredBounce(
            token: landingToken,
            delay: landingDelay + Double(cover.depth) * SortPileView.landingStagger
        )
    }

    /// The gap between two covers' arrivals. The interval the onboarding plank already
    /// settles its books with, so the app has one number for "one at a time".
    static let landingStagger: Double = 0.08

    /// One cover's frame. Narrow enough that a fan of five still shows five spines' worth of
    /// colour, tall enough to keep the book's own proportions.
    private var coverSize: CGSize {
        let coverWidth: CGFloat = pile.isSingleCover ? width * 0.52 : width * 0.46
        return .init(
            width: coverWidth,
            height: min(SortGridMetrics.artHeight, coverWidth / SortGridMetrics.coverAspectRatio)
        )
    }

    /// Where a cover sits relative to the front one, which stays put in the middle of the card.
    ///
    /// The fan opens **alternately** — one cover right, the next left, then further right, then
    /// further left — so the pile stays roughly centred on the book a drag will take. Opening
    /// one way only walked the whole pile off towards the right edge as it grew. Roughly, not
    /// exactly: each cover also leans by its own derived angle, and that is what keeps it
    /// looking handled.
    private func offset(for cover: SortPile.Cover) -> CGSize {
        guard pile.isSingleCover == false, cover.depth > 0 else { return .zero }
        let step: CGFloat = width * 0.075
        let rank: CGFloat = .init((cover.depth + 1) / 2)
        let side: CGFloat = cover.depth.isMultiple(of: 2) ? -1 : 1
        return .init(
            width: side * rank * step,
            height: rank * step * 0.5
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
