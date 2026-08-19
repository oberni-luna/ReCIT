//
//  ShelfFocusOverlayView.swift
//  ReCIT_iOS
//
//  Selection mode, drawn over the whole app: the screen veiled, the pressed book redrawn
//  sharp and grown where it stands on the shelf, and — once selection mode arms — that book's
//  cell sitting directly beneath it.
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

    var body: some View {
        ZStack {
            veil
            if let book = focus.book {
                if focus.isArmed {
                    cell(for: book)
                }
                self.book(book)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// Blurred and washed out, but never opaque. A material is the only thing that blurs what
    /// is behind it, and at half opacity it half-blurs — which is exactly the point.
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

    /// The book's cell, resting just above the grown book so a thumb on the shelf never
    /// covers it.
    private func cell(for book: ShelfFocusModel.Book) -> some View {
        ShelfFocusBookCell(item: book.item)
            // A box from the top of the screen down to the cell's resting line, with the cell
            // pinned to its bottom — so the cell lands there whatever height its text runs to.
            .frame(height: book.cellBottom, alignment: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .transition(.opacity)
    }
}
