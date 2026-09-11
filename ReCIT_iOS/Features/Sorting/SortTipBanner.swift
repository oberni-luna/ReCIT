//
//  SortTipBanner.swift
//  ReCIT_iOS
//
//  The astuce, where it is shown: the green card, and — for the aims that carry it — the
//  pointer under it, aimed at what the card is talking about.
//
//  **Two places on the screen, one card.** SORT-1 sits between the carousel's header and the
//  covers, inside the anchored panel, so its pointer lands exactly above the first cover and
//  the card covers nothing the user is about to drag or drop onto. SORT-2 and SORT-3 sit over
//  the block of controls, directly above the button each is about — « Appliquer » for one,
//  the wand for the other — for the same reason: they must point at their control without
//  lying over it. In every case the panel grows and the grid scrolls in what is left, which
//  is what it does anyway.
//
//  **The pointer is not always drawn here.** Aimed at a book it is, at an inset this screen
//  can measure. Aimed at a button of the action bar it is not: only `ManualSortActionBar`
//  knows where its middle button and its wand sit, so the pointer is laid out by the panel on
//  the guide the bar publishes — see `SortTipAim`, `HorizontalAlignment.sortApply` and
//  `.sortProposal`.
//
//  **The `TipGroup(.firstAvailable)` is what guarantees one card at a time.** It holds all
//  three astuces, and TipKit shows the first eligible one and no more. Which of them is
//  *eligible* is not TipKit's business — `SortTipGate` decides it and the screen sets each
//  tip's parameter from the answer, so at most one of them is ever true and the two mounting
//  places cannot both draw a card.
//
//  **`.firstAvailable` and not `.ordered`, and the order still holds.** An ordered group does
//  not move on to its next astuce until the previous one has been **invalidated**, and this
//  feature deliberately never invalidates anything: a close is "not now" and a learned gesture
//  is `TipsStore`'s record, not TipKit's (see `TipCardStyle`). So an ordered group stayed on
//  SORT-1 for good and SORT-2 and SORT-3 never appeared — the pointer above « Appliquer » was
//  drawn, with no card over it, because the panel places it from the gate's answer while the
//  card comes from TipKit's. The order the astuces are offered in is `SortTip`'s declaration
//  order, enforced by `SortTipGate`, so nothing is lost by letting TipKit pick whichever one
//  the gate has made eligible.
//
//  See PRD 0013 and issues 0077, 0079 and 0080.
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

    /// The astuces of this surface, in the order they are owed. A group rather than three
    /// independent tips: two cards on a screen of three étagère cards leave nothing to sort.
    /// `.firstAvailable`, because the one the gate has made due is the one to show — see the
    /// note at the top of this file on why `.ordered` showed only ever the first.
    @State private var tips: TipGroup = .init(.firstAvailable) {
        SortDragToFileTip()
        SortNothingSavedYetTip()
        SortLetItProposeTip()
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
