//
//  ShelfEmptyStateView.swift
//  ReCIT_iOS
//
//  What a user with no étagère sees where the carousel would be: one empty shelf — wash
//  and plank, no books — with a note resting on it. Sized from `ShelfCardMetrics` like a
//  real shelf, so the day the first étagère replaces this card the plank doesn't move.
//
//  The note sits *on* the shelf, in the band where books would stand, rather than stuck
//  under the plank the way a real étagère's name is. That difference is the point: a shelf
//  label names a shelf, and this one is a reminder left on an empty one.
//
//  It is *not* a carousel item, which is why it isn't drawn inside one: it is the
//  alternative to the carousel rather than one card among many. A horizontal, snapping,
//  view-aligned scroll view holding a single card would offer a paging gesture with
//  nowhere to page to, and would keep the empty branch entangled with the layout of the
//  populated one. `ShelvesContent` therefore picks one or the other.
//
//  No "+" glyph: the section header carries the create action (PRD 0003), and a UI symbol
//  floating inside a painted illustration read as pasted on.
//
//  It does carry a chevron, which it did not when it opened a create sheet. Since PRD 0006
//  the card leads into the auto-sort flow — a push — so the chevron stopped being a lie.
//  On a device that cannot run Apple Intelligence `ShelvesContent` still sends the press to
//  the create form, so the glyph over-promises there; that is the cheaper wrong than a card
//  whose affordance changes shape depending on the hardware.
//
//  Which of the two it is, is deliberately not this view's business: it paints an empty
//  shelf and reports a press. The page knows what the app can currently do.
//

import SwiftUI

struct ShelfEmptyStateView: View {
    let width: CGFloat
    let onTap: () -> Void

    private var metrics: ShelfCardMetrics { .init(width: width) }

    /// How far the wash extends below the plank, matching `ShelfRowView` so the two cards'
    /// paint ends at the same place.
    private let washBelow: CGFloat = 16
    /// How far the label's bottom edge sits above the plank's top. Unlike a real shelf's
    /// label — which is stuck onto the plank's *bottom* edge — this one rests *on* the
    /// shelf, standing in the band where books would be. It is a note left on an empty
    /// shelf, not a name for it.
    private let labelAbovePlank: CGFloat = 8

    var body: some View {
        Button(action: onTap) {
            shelfStack
                .padding(.top, metrics.topRoom)
                .frame(width: width)
            // The whole card is the target, painted or not — the plank, the empty band
            // above it and the label alike. Two hit zones inside one painted card is the
            // problem the card-level pencil's removal solved.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var shelfStack: some View {
        ZStack(alignment: .bottom) {
            Image("ShelfWash")
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .offset(y: washBelow)
                .opacity(0.92)
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                // The band a real shelf's books stand in. No books here — the note stands
                // in their place, bottom-aligned so it rests on the plank below it. The
                // band keeps its full height regardless, so the plank lands where it does
                // on a populated card.
                ShelfLabelView(
                    text: "Todo\n☐ Ranger mes livres",
                    maxWidth: metrics.booksWidth,
                    lineLimit: 2
                )
                .padding(.bottom, labelAbovePlank)
                .frame(width: width, height: metrics.zoneHeight, alignment: .bottom)
                Image("ShelfPlank")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: metrics.cardHeight)
    }
}
