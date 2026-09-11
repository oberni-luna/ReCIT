//
//  SortProposalAlignment.swift
//  ReCIT_iOS
//
//  Where the proposal control sits, published by the action bar and read by SORT-3's pointer.
//
//  The same mechanism as `HorizontalAlignment.sortApply`, and for the same reason: the round
//  wand button's centre is not a number anyone outside `ManualSortActionBar` can work out —
//  the bar closes up around a control that is absent on an ineligible device, the pill beside
//  it takes whatever width its label needs, and every one of them grows with the body text.
//  So the bar states it once, as a custom alignment guide, and the pointer is laid out on it
//  (PRD 0013).
//
//  **Pointer only, never the card**, exactly as for « Appliquer »: the card keeps the panel's
//  full width, and a full-width view aligned on a guide sitting near the trailing edge would
//  drag the whole column sideways. Pointer and card are two layout children of the panel.
//
//  See issues 0079 and 0080.
//

import SwiftUI

extension HorizontalAlignment {

    private enum SortProposalID: AlignmentID {
        /// The centre, for everything that has not said otherwise — so a view that never
        /// meets the action bar still lays out sensibly.
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }

    /// The horizontal centre of the proposal control.
    static let sortProposal: HorizontalAlignment = .init(SortProposalID.self)
}
