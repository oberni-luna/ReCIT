//
//  ManualSortActionBar.swift
//  ReCIT_iOS
//
//  The foot of the sorting surface: ask for a proposal, save, or get out.
//
//  **The third button's label is derived from whether the stack is empty**, with no
//  "has applied" flag anywhere. Stack empty: nothing to save, so the primary is inert
//  and the third reads « Terminer » and closes the screen. Stack not empty: the
//  primary is live and the third reads « Annuler » and throws the stack away. A
//  successful apply empties the stack, so « Terminer » appears by itself; taking
//  sorting up again turns it back into « Annuler », which is true, because there is
//  once more something to discard. A sticky flag would leave the screen's only
//  destructive button labelled « Terminer » — see PRD 0008.
//
//  Only the empty branch is reachable in this slice, and the rule is written whole
//  anyway, so the slices that fill the stack change nothing here.
//
//  « Proposer un rangement » is absent rather than disabled while the AI proposal is
//  unbuilt (slice 0042): a button that does nothing is worse than no button, and the
//  screen is meant to be entirely usable on a device that can never run the model.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortActionBar: View {

    /// The one input the whole bar is derived from.
    let hasPendingChanges: Bool

    let onApply: () -> Void
    let onDiscard: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: .small) {
            Button("manual_sort.apply", action: onApply)
                .buttonStyle(.primary())
                .disabled(hasPendingChanges == false)

            Button(
                hasPendingChanges ? "manual_sort.discard" : "manual_sort.finish",
                action: hasPendingChanges ? onDiscard : onFinish
            )
            .buttonStyle(.secondary())
        }
        .frame(maxWidth: .infinity)
    }
}
