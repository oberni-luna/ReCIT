//
//  SortTipBanner.swift
//  ReCIT_iOS
//
//  The astuce, where it is shown: the green card, and under it the pointer aimed at the
//  first book of « Livres à ranger ».
//
//  **It sits between the carousel's header and the carousel itself**, inside the anchored
//  panel, rather than floating over the screen. Two things follow from that and both are
//  requirements: the pointer lands exactly above the first cover it is talking about, and
//  the card covers nothing — not the books the user is about to drag, not the étagère cards
//  they are about to drop them on, not the controls. The panel grows and the grid scrolls in
//  what is left, which is what it does anyway.
//
//  **The `TipGroup(.ordered)` is what guarantees one card at a time.** It holds SORT-1 today
//  and gains SORT-2 and SORT-3 (issues 0079, 0080); TipKit shows the first eligible one and
//  no more. Which of them is *eligible* is not TipKit's business — `SortTipGate` decides it
//  and the screen sets each tip's parameter from the answer.
//
//  See PRD 0013 and issue 0077.
//

import SwiftUI
import TipKit

struct SortTipBanner: View {

    /// Where the surface's measurements come from — here, the width of a book card, which is
    /// the only thing that says where the first cover's centre is.
    let metrics: SortGridMetrics

    /// Puts the card away without teaching anything. A cross is "not now", and the account's
    /// record of learned gestures is not touched by it.
    let onClose: () -> Void

    /// The astuces of this surface, in the order they are owed. Ordered rather than a set of
    /// independent tips: two cards on a screen of three étagère cards leave nothing to sort.
    @State private var tips: TipGroup = .init(.ordered) {
        SortDragToFileTip()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            if let tip = tips.currentTip {
                TipView(tip)
                    .tipViewStyle(TipCardStyle(onClose: onClose))
                    .padding(.horizontal, .medium)

                TipPointerView()
                    .padding(.leading, pointerInset)
            }
        }
    }

    /// How far in the pointer sits: the carousel's own margin plus half a book card, less
    /// half the pointer — so its apex falls on the centre of the first cover. Derived from
    /// the same metrics the carousel lays itself out with, so the two cannot drift apart.
    private var pointerInset: CGFloat {
        let firstBookCentre: CGFloat = SortGridMetrics.shelfSpacing + metrics.bookColumnWidth / 2

        return max(0, firstBookCentre - TipPointerView.size.width / 2)
    }
}
