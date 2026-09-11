//
//  SortApplyAlignment.swift
//  ReCIT_iOS
//
//  Where « Appliquer » sits, published by the action bar and read by the astuce's pointer.
//
//  SORT-2's card points at the middle button of `ManualSortActionBar`, and that button's
//  centre is not a number anyone else can work out: the bar closes up around a proposal
//  control that is absent on an ineligible device, and the round buttons grow with the body
//  text. So the bar states it, once, as a custom alignment guide, and the pointer is laid out
//  on it — which is what alignment guides are for, and what keeps the card ignorant of what
//  it aims at (PRD 0013).
//
//  **The card cannot ride on the same guide**, which is why only the pointer does: the card
//  keeps the panel's full width, and a full-width view aligned on an off-centre guide would
//  push the whole column sideways. Pointer and card are therefore two layout children of the
//  panel, not one.
//
//  See issue 0079.
//

import SwiftUI

extension HorizontalAlignment {

    private enum SortApplyID: AlignmentID {
        /// The centre, for everything that has not said otherwise — so a view that never
        /// meets the action bar still lays out sensibly.
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }

    /// The horizontal centre of « Appliquer ».
    static let sortApply: HorizontalAlignment = .init(SortApplyID.self)
}
