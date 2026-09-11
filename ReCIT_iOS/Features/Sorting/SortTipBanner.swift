//
//  SortTipBanner.swift
//  ReCIT_iOS
//
//  The astuce, where it is shown: the green card, and — for the aims that carry it — the
//  pointer under it, aimed at what the card is talking about.
//
//  **Two places on the screen, one card.** SORT-1 sits between the carousel's header and the
//  covers, inside the anchored panel, so its pointer lands exactly above the first cover and
//  the card covers nothing the user is about to drag or drop onto. SORT-2 sits over the block
//  of controls, directly above « Appliquer », for the same reason: it must point at the
//  button it is about, and it must not lie over it. In both cases the panel grows and the
//  grid scrolls in what is left, which is what it does anyway.
//
//  **The pointer is not always drawn here.** Aimed at a book it is, at an inset this screen
//  can measure. Aimed at « Appliquer » it is not: only `ManualSortActionBar` knows where its
//  middle button sits, so the pointer is laid out by the panel on the guide the bar
//  publishes — see `SortTipAim` and `HorizontalAlignment.sortApply`.
//
//  **The `TipGroup(.ordered)` is what guarantees one card at a time.** It holds SORT-1 and
//  SORT-2 today and gains SORT-3 (issue 0080); TipKit shows the first eligible one and no
//  more. Which of them is *eligible* is not TipKit's business — `SortTipGate` decides it and
//  the screen sets each tip's parameter from the answer, so at most one of them is ever true
//  and the two mounting places cannot both draw a card.
//
//  See PRD 0013 and issues 0077 and 0079.
//

import SwiftUI
import TipKit

struct SortTipBanner: View {

    /// What this card points at, and therefore whether it carries its own pointer and how far
    /// off the edges it sits.
    let aim: SortTipAim

    /// Puts the card away without teaching anything. A cross is "not now", and the account's
    /// record of learned gestures is not touched by it.
    let onClose: () -> Void

    /// The astuces of this surface, in the order they are owed. Ordered rather than a set of
    /// independent tips: two cards on a screen of three étagère cards leave nothing to sort.
    @State private var tips: TipGroup = .init(.ordered) {
        SortDragToFileTip()
        SortNothingSavedYetTip()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            if let tip = tips.currentTip {
                TipView(tip)
                    .tipViewStyle(TipCardStyle(onClose: onClose))
                    .padding(.horizontal, aim.cardInset)

                if let pointerInset = aim.pointerInset {
                    TipPointerView()
                        .padding(.leading, pointerInset)
                }
            }
        }
    }
}
