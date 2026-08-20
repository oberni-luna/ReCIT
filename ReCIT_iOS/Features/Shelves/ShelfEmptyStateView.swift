//
//  ShelfEmptyStateView.swift
//  ReCIT_iOS
//
//  What a user with no étagère sees where the carousel would be: one empty shelf — wash
//  and plank, no books — with a paper label inviting them to fill it. Sized from
//  `ShelfCardMetrics` like a real shelf, so the day the first étagère replaces this card
//  the plank doesn't move.
//
//  It is *not* a carousel item, which is why it isn't drawn inside one: it is the
//  alternative to the carousel rather than one card among many. A horizontal, snapping,
//  view-aligned scroll view holding a single card would offer a paging gesture with
//  nowhere to page to, and would keep the empty branch entangled with the layout of the
//  populated one. `ShelvesContent` therefore picks one or the other.
//
//  No "+" glyph: the section header carries the create action (PRD 0003), and a UI symbol
//  floating inside a painted illustration read as pasted on. No chevron on the label
//  either — its text is centred, so a trailing glyph reads as off-centre, and where the
//  card leads is not fixed: `ShelvesContent` sends it to the auto-sort flow, or to the
//  create form on a device that cannot run Apple Intelligence (PRD 0006). A chevron would
//  promise a push that only sometimes happens.
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
    /// How far the label's *top* rides up over the plank's bottom edge — the shelf label's
    /// own inset. Anchored from the top, so wrapping onto a second line simply extends
    /// further down and the inset still holds.
    private let labelOverlap: CGFloat = 14

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                shelfStack
                    .padding(.top, metrics.topRoom)
                ShelfLabelView(
                    text: "Todo : ranger mes livres dans une étagère",
                    maxWidth: metrics.booksWidth,
                    showsChevron: false,
                    lineLimit: 2,
                    alignment: .center
                )
                .padding(.top, -labelOverlap)
                .zIndex(1)
            }
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
                // The band a real shelf's books stand in, left empty here so the plank
                // lands at the same height as on a populated card.
                Color.clear
                    .frame(width: width, height: metrics.zoneHeight)
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
