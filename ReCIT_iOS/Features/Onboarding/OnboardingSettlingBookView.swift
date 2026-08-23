//
//  OnboardingSettlingBookView.swift
//  ReCIT_iOS
//
//  One book on the bilan's plank: painted the way the shelf paints it, placed where the shelf's
//  own layout puts it, and coming down onto it once.
//
//  Eased, not sprung. A spring would make a book bounce as it landed, which reads as an object
//  dropped rather than an object put away — and the design system already spends its springs on
//  picking a book *up* (`ShelfRowView.swift:201`), so borrowing one here would blur what a spring
//  means in this app.
//
//  Under Reduce Motion the fall goes and the fade stays, and so does the stagger: the stagger is
//  what carries the meaning — one book at a time — and a fade is not a movement. Turning it off
//  would not calm the screen, it would delete the sentence the screen is saying.
//
//  The animation is scoped to `hasSettled` rather than left open, which is what makes a
//  late-arriving cover harmless: the strip or the image landing redraws this book inside a frame
//  it already occupies, and touches nothing the animation is watching.
//
//  See PRD 0007 and `grill-me/design/onboarding/motion.md`.
//

import SwiftUI

struct OnboardingSettlingBookView: View {

    let item: InventoryItem
    /// Where this book sits at rest, in the books band's coordinates — the shelf's own geometry,
    /// resolved by `ShelfBooksLayout`.
    let frame: CGRect
    let presentation: ShelfFocusModel.Presentation
    /// The last standing book on a shelf leans; this one leans with it.
    let leaning: Bool
    /// False while the book is still on its way, true once it has been asked to land. Owned by the
    /// run, so every book in it travels off the same single flip.
    let hasSettled: Bool
    /// This book's turn: its index's share of the run's stagger.
    let delay: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How long one book takes to arrive.
    private let duration: TimeInterval = 0.32
    /// How far above the plank it starts. Zero under Reduce Motion, which is the whole of what
    /// that setting changes here.
    private var fall: CGFloat { reduceMotion ? 0 : 32 }

    var body: some View {
        Group {
            if presentation == .cover {
                // Bottom-anchored, like the shelf's own lone book: the frame is a fixed
                // portrait and a wider cover would otherwise settle *above* the plank.
                ShelfCoverView(item: item, size: frame.size, alignment: .bottom)
            } else {
                PaintedBookView(
                    edition: item.edition,
                    size: frame.size,
                    orientation: presentation.orientation
                ) { ink in
                    ShelfBookTitle(
                        title: item.edition?.title ?? "",
                        ink: ink,
                        orientation: presentation.orientation,
                        size: frame.size
                    )
                }
            }
        }
        .rotationEffect(
            leaning ? .degrees(-ShelfBooksLayout.leanDegrees) : .zero,
            anchor: .bottomTrailing
        )
        .opacity(hasSettled ? 1 : 0)
        .offset(y: hasSettled ? 0 : -fall)
        .animation(.easeOut(duration: duration).delay(delay), value: hasSettled)
        .position(x: frame.midX, y: frame.midY)
    }
}
