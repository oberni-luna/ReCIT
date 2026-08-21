//
//  ManualSortEmptySectionRow.swift
//  ReCIT_iOS
//
//  What an étagère holding nothing says, and — more to the point — the state in which its
//  header becomes the thing you drop a book onto.
//
//  It used to be a row of its own, under the header. That cost the drop its smoothness:
//  filling the étagère *deleted* that row, while the list had just performed a
//  length-preserving reorder, so SwiftUI had an insertion and a deletion to animate on top
//  of the move — the note and the arriving book overlapped for a third of a second. The
//  sentence now sits inside `ManualSortSectionHeader`, which is the row the finger aims at
//  in that state, and a move no longer changes how many rows there are. See
//  `ManualSortRows`.
//
//  The pile says something different from an étagère: an empty « À ranger » is the proof
//  the work is done, not an invitation to fill it.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortEmptySectionRow: View {

    let isUnshelved: Bool

    var body: some View {
        Text(isUnshelved ? "manual_sort.unshelved.empty" : "manual_sort.shelf.empty")
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
