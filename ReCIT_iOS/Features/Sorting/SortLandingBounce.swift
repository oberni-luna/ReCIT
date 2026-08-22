//
//  SortLandingBounce.swift
//  ReCIT_iOS
//
//  The bounce a book makes when it lands on a pile: it appears a little too large and a
//  little too high, then settles.
//
//  It is keyed on **which** book is in front rather than on a "just dropped" flag, so it
//  fires for a drop, for a proposal landing several books at once, and for an apply putting
//  a shelf's covers back — one rule, three callers, and nothing to remember to set. A pile
//  whose front book has not changed does not animate, which is what keeps a scrolling grid
//  still.
//
//  Kept under Reduce Motion, deliberately, on the owner's call: the movement is how this
//  screen says a book went in, and there is a spinner on the étagère being written for the
//  reading that does not depend on motion (PRD 0009). Recorded as a divergence.
//

import SwiftUI

extension View {

    /// Bounces this view whenever `bookId` changes to a different book.
    func sortLandingBounce(bookId: String?) -> some View {
        modifier(SortLandingBounce(bookId: bookId))
    }
}

struct SortLandingBounce: ViewModifier {
    let bookId: String?

    /// Whether the arriving state is being held — flipped on for one frame when the book
    /// changes, then off, which is what the spring animates away from.
    @State private var isArriving: Bool = false

    /// The book the bounce has already been played for, so a re-render with the same front
    /// book does not replay it.
    @State private var playedFor: String?

    func body(content: Content) -> some View {
        content
            .scaleEffect(isArriving ? 1.15 : 1)
            .offset(y: isArriving ? -12 : 0)
            .animation(.spring(response: 0.32, dampingFraction: 0.55), value: isArriving)
            .onChange(of: bookId, initial: true) { _, newValue in
                guard let newValue, newValue != playedFor else { return }
                // First render is not an arrival: the pile was already like this when the
                // screen opened, and bouncing every card on appearance would make opening
                // the surface look like a slot machine.
                let isFirstReading: Bool = playedFor == nil
                playedFor = newValue
                guard isFirstReading == false else { return }

                isArriving = true
                Task {
                    // One frame held, then released — the spring does the rest. A duration
                    // rather than a transition because the view itself is not being
                    // inserted: the same cover slot now holds a different book.
                    try? await Task.sleep(for: .milliseconds(16))
                    isArriving = false
                }
            }
    }
}

/// Bounces a pile's covers one after another, oldest first, when a token changes — the
/// arrival an apply plays as an étagère lands, and the one a proposal plays on every card it
/// touched.
///
/// A stagger rather than one bounce for the whole card: `0.08 s` apart is what says *one at a
/// time*, and it is the same interval the onboarding plank settles its books with, so the app
/// has one number for this and not two.
struct SortStaggeredBounce: ViewModifier {
    /// Changes when there is something to play. Nil plays nothing.
    let token: String?
    let delay: Double

    @State private var isArriving: Bool = false
    @State private var playedFor: String?

    func body(content: Content) -> some View {
        content
            .scaleEffect(isArriving ? 1.12 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.55), value: isArriving)
            .onChange(of: token) { _, newValue in
                guard let newValue, newValue != playedFor else { return }
                playedFor = newValue
                Task {
                    try? await Task.sleep(for: .seconds(delay))
                    isArriving = true
                    try? await Task.sleep(for: .milliseconds(16))
                    isArriving = false
                }
            }
    }
}

extension View {

    /// Bounces this view `delay` seconds after `token` changes.
    func sortStaggeredBounce(token: String?, delay: Double) -> some View {
        modifier(SortStaggeredBounce(token: token, delay: delay))
    }
}
