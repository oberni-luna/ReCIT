//
//  ManualSortEmptySectionRow.swift
//  ReCIT_iOS
//
//  What a section with no books under it says, and — more to the point — the surface
//  it gives a finger to aim at.
//
//  A section can be emptied by the very gesture this slice adds: drag the last book off
//  an étagère and it stays on screen with nothing in it. Without this row that étagère
//  would be a drop target zero points tall, so the book could never be put back — the
//  gesture would stop being its own inverse, which is the whole reason the PRD leaves
//  single-change undo out.
//
//  The pile keeps its section for the same reason, and says something different: an
//  empty « À ranger » is the proof the work is done, not an invitation to fill it.
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
