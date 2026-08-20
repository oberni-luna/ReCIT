//
//  ShelfFocusOverlayView.swift
//  ReCIT_iOS
//
//  Selection mode, drawn over the whole app: the screen veiled, the pressed book redrawn
//  sharp and grown where it stands on the shelf, and — once selection mode arms — that book's
//  cell pinned to the top of the screen, over everything.
//
//  The cell used to be placed relative to the *card*, just above the tallest book the shelf
//  could grow. That worked only while the card sat where it was first drawn: scroll the page
//  a little before pressing and the cell followed the card off the top of the screen. It is
//  now anchored to the screen instead, so where the shelf happens to be cannot move it.
//
//  Which means the cell and the grown book can now occupy the same space, and the cell wins:
//  it lives in a layer above the one the book is drawn in.
//
//  What keeps the cell readable is `VariableBlurView` behind it — a real radius ramp, because
//  nothing in SwiftUI can express one. Read that file before touching it: it costs a private
//  API, and it says so.
//
//  Two things that did not work, so they are not tried again. A material masked or faded into
//  a gradient composites offscreen and degrades to a flat wash. And `.scrollEdgeEffectStyle`
//  blurs a scroll view's own content passing under its edge, which is never the navigation
//  bar drawn above it — so the page title stayed perfectly sharp.
//
//  The veil stops at half opacity on purpose: the rest of the étagère has to stay visible
//  underneath, so the finger can see where it is going. It rides the press's progress, so the
//  screen recedes as the book grows rather than snapping at the end.
//
//  Hit testing is off throughout: the finger keeps talking to the shelf's own recognizer
//  underneath, which is what lets the slide keep choosing books. See ADR 0006.
//

import SwiftUI

struct ShelfFocusOverlayView: View {
    let focus: ShelfFocusModel

    /// How far the veil ever goes. Half, so the shelf reads through it.
    private let veilStrength: Double = 0.5
    /// How much of the veil is a plain wash rather than blur.
    private let wash: Double = 0.5

    /// Where the cell's bottom edge lands, in screen coordinates — measured rather than
    /// assumed, because the title runs to one line or two. It is where the blur behind the
    /// cell finishes fading.
    @State private var cellBottom: CGFloat = 0

    var body: some View {
        // Two layers on purpose. The inner one ignores the safe area, because the book is
        // positioned in screen coordinates and needs an origin at the screen's own corner.
        // The outer one does not, which is what puts the cell a safe area below the top
        // without anybody having to read the inset — and puts it above the book.
        ZStack(alignment: .top) {
            ZStack {
                veil
                if let book = focus.book {
                    self.book(book)
                }
                // Above the book, so the grown book softens under the cell too rather than
                // cutting through it sharply.
                legibilityBlur
            }
            .ignoresSafeArea()

            if let book = focus.book, focus.isArmed {
                cell(for: book)
            }
        }
        .allowsHitTesting(false)
    }

    /// The graded blur behind the cell: full strength at the top of the screen, gone by the
    /// cell's bottom edge, and nothing below that.
    ///
    /// The view's height is exactly the region being blurred — no tail. The seam an effect
    /// view's bottom edge would otherwise draw is handled by the fade reaching zero there,
    /// not by pushing the edge somewhere else: extending the view past the cell blurred the
    /// shelf below it, which is worse than the seam was.
    ///
    /// Faded by `alpha` rather than inserted and removed, which a visual effect view handles
    /// properly — the thing a material does not.
    private var legibilityBlur: some View {
        VariableBlurView(maxRadius: 25)
            .frame(height: cellBottom)
            .frame(maxHeight: .infinity, alignment: .top)
            .opacity(focus.isArmed ? 1 : 0)
            .allowsHitTesting(false)
    }

    /// Washed out, but never opaque — the rest of the étagère has to stay visible so the
    /// finger can see where it is going.
    ///
    /// Note what this is not: fading a material composites it offscreen, where it has no
    /// backdrop left to sample, so this reads as a plain translucent wash rather than the
    /// half-blur the material implies. It has always rendered that way; the description used
    /// to claim otherwise.
    private var veil: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(DesignSystem.Color.backgroundDefault.color.opacity(wash))
            .opacity(focus.progress * veilStrength)
            .ignoresSafeArea()
    }

    /// The pressed book, sharp above the veil, grown about its centre. Nothing here animates
    /// from one book to the next: the finger is picking, and a cover morphing into another
    /// cover reads as a glitch rather than a transition.
    @ViewBuilder
    private func book(_ book: ShelfFocusModel.Book) -> some View {
        Group {
            if book.presentation == .cover {
                ShelfCoverView(item: book.item, size: book.frame.size, showsPlaceholder: false)
            } else {
                PaintedBookView(
                    edition: book.item.edition,
                    size: book.frame.size,
                    orientation: book.presentation.orientation,
                    showsPlaceholder: false
                ) { ink in
                    ShelfBookTitle(
                        title: book.item.edition?.title ?? "",
                        ink: ink,
                        orientation: book.presentation.orientation,
                        size: book.frame.size
                    )
                }
            }
        }
        .rotationEffect(book.leaning ? .degrees(-ShelfBooksLayout.leanDegrees) : .zero, anchor: .bottomTrailing)
        .scaleEffect(focus.growth, anchor: .center)
        .position(x: book.frame.midX, y: book.frame.midY)
    }

    /// The book's cell, at the top of the screen: a margin below the status bar, centred, and
    /// clear of wherever on the shelf the finger happens to be.
    private func cell(for book: ShelfFocusModel.Book) -> some View {
        ShelfFocusBookCell(item: book.item)
            .padding(.top, .small)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .global).maxY
            } action: { bottom in
                cellBottom = bottom
            }
            .transition(.opacity)
    }
}
