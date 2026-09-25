//
//  ShelfEmptyStateView.swift
//  ReCIT_iOS
//
//  What a user with no étagère sees where the carousel would be: one empty shelf — wash
//  and plank, no books — with the step they are at written above it and one paper tag per
//  thing to do resting on it. Sized from `ShelfCardMetrics` like a real shelf, so the day
//  the first étagère replaces this card the plank stays at the same height. It is centred on
//  the screen rather than parked where the carousel's first card sits, so that one step is
//  sideways.
//
//  Everything stands in the band where books would be: the sentence at the top of it, the
//  tags at the bottom, on the plank. Nothing is added above or below the card, which is what
//  keeps its height — and so the plank — exactly that of a populated shelf.
//
//  What is written, and which tags, is a `ShelfEmptyStateErrand`: an empty inventory asks to
//  be filled, by scanning or by searching; books on no étagère ask to be arranged. This view
//  paints the errand and reports which tag was pressed; where each press goes is decided in
//  one place, by `ShelvesContent`. See docs/features/0021.
//
//  The card itself is no longer a button. It was one while it carried a single note; with two
//  tags side by side, a press anywhere on the card would have to guess which one was meant.
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

import SwiftUI

struct ShelfEmptyStateView: View {
    let width: CGFloat
    /// What the shelf asks for. Decided by `ShelvesContent`, together with where each tag goes.
    let errand: ShelfEmptyStateErrand
    let onAction: (ShelfEmptyStateAction) -> Void

    private var metrics: ShelfCardMetrics { .init(width: width) }

    /// How far the wash extends below the plank, matching `ShelfRowView` so the two cards'
    /// paint ends at the same place.
    private let washBelow: CGFloat = 16
    /// How far the tags' bottom edge sits above the plank's top: close enough to read as
    /// resting on it once the lean lifts one corner.
    private let tagsAbovePlank: CGFloat = 2

    var body: some View {
        shelfStack
            .padding(.top, metrics.topRoom)
            .frame(width: width)
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
                // The band a real shelf's books stand in. It keeps its full height whatever
                // is written in it, so the plank lands where it does on a populated card.
                VStack(spacing: 0) {
                    ShelfEmptyStateCaption(errand: errand)
                        .frame(width: metrics.booksWidth)
                    Spacer(minLength: DesignSystem.Spacing.small.rawValue)
                    tags
                        .padding(.bottom, tagsAbovePlank)
                }
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

    /// The tags, side by side and centred on the plank. They may use the plank's full width
    /// rather than the books' — two tags inside the books' margins leave too little for
    /// either on a small phone.
    private var tags: some View {
        HStack(alignment: .bottom, spacing: .medium) {
            ForEach(errand.actions, id: \.self) { action in
                ShelfActionTag(action: action) {
                    onAction(action)
                }
            }
        }
        .padding(.horizontal, .small)
        .frame(width: width)
    }
}
