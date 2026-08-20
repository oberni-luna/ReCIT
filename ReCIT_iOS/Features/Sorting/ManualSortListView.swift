//
//  ManualSortListView.swift
//  ReCIT_iOS
//
//  The surface once the snapshot is frozen: one section per étagère, then the pile,
//  then the buttons.
//
//  Everything it draws comes out of `SortProjection`, which is a pure function of the
//  snapshot and the change stack — so the screen has no state of its own to keep in
//  step with anything, and the rule that every book sits in exactly one section is
//  enforced before this view ever sees the data.
//
//  The buttons sit at the foot of the list rather than in a pinned bar. The design
//  proposes a pinned bar; the list already stacks a tab bar under it, and two bars is
//  166 pt of chrome on a screen whose whole point is showing books. Kept in the list,
//  as `AutoSortPlanView` does — and revisited if the sections ever grow long enough
//  that the buttons become hard to reach.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortListView: View {
    let session: SortSessionModel
    let onFinish: () -> Void

    var body: some View {
        List {
            ForEach(session.projection.sections) { section in
                ManualSortSectionView(section: section)
            }

            Section {
                ManualSortActionBar(
                    hasPendingChanges: session.hasPendingChanges,
                    // Inert while the stack is empty, which it always is here. The
                    // apply itself is slice 0040.
                    onApply: {},
                    onDiscard: session.discardChanges,
                    onFinish: onFinish
                )
            }
            .listRowBackground(DesignSystem.Color.clear.color)
        }
        .applyListBackground()
    }
}
