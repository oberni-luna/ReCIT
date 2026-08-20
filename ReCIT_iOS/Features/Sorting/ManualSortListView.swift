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
//  enforced before this view ever sees the data. A drop appends one change and the
//  sections are recomputed; nothing here moves a book by hand, which is why a book
//  cannot be in two places even for a frame.
//
//  It owns exactly one piece of state: which drop destination the finger is over. That
//  cannot live in a section, because only one section may be highlighted at a time and
//  no section can see the others.
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

    @State private var targeted: ManualSortDropTarget?

    var body: some View {
        List {
            ForEach(session.projection.sections) { section in
                ManualSortSectionView(
                    section: section,
                    isDropTarget: targeted?.section == section.id,
                    onDrop: { drop($0, onto: section.id) },
                    onTargeted: setTargeted
                )
            }

            Section {
                ManualSortActionBar(
                    hasPendingChanges: session.hasPendingChanges,
                    // Live as soon as there is something to save, and doing nothing
                    // yet: applying is slice 0040. The alternative — keeping it
                    // disabled until the write exists — would put the button rule on
                    // a flag, which is exactly what PRD 0008 forbids.
                    onApply: {},
                    onDiscard: session.discardChanges,
                    onFinish: onFinish
                )
            }
            .listRowBackground(DesignSystem.Color.clear.color)
        }
        .applyListBackground()
    }

    /// One drop, one change. The origin travels with the book, so the stack records
    /// both ends of the move without asking the projection where the book was.
    private func drop(
        _ transfers: [SortBookTransfer],
        onto section: SortSection.ID
    ) -> Bool {
        targeted = nil
        for transfer in transfers {
            session.moveBook(transfer.bookId, from: transfer.origin, to: section)
        }
        return transfers.isEmpty == false
    }

    /// A destination only gives up the highlight if it is still the one holding it.
    /// Crossing from one row to the next fires the arrival and the departure in an
    /// order nobody promises, and clearing unconditionally would blank the band the
    /// finger is over half the time.
    private func setTargeted(_ isTargeted: Bool, _ target: ManualSortDropTarget) {
        if isTargeted {
            targeted = target
        } else if targeted == target {
            targeted = nil
        }
    }
}
