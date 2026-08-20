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
//  **While a run is writing, both buttons stand down.** The escape hatch is withdrawn
//  for the duration exactly as the auto-sort screen withdraws its toolbar exit:
//  discarding a stack that is halfway through being written, or firing a second run on
//  top of the first, would both destroy the account of what landed. The writes
//  themselves are owned by the session and carry on regardless of this screen.
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

    /// Whether a run is writing right now. It disables rather than relabels: what the
    /// buttons would say is still true, they are simply not offered.
    let isApplying: Bool

    let onApply: () -> Void
    let onDiscard: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: .small) {
            Button("manual_sort.apply", action: onApply)
                .buttonStyle(.primary())
                .disabled(hasPendingChanges == false || isApplying)

            Button(
                hasPendingChanges ? "manual_sort.discard" : "manual_sort.finish",
                action: hasPendingChanges ? onDiscard : onFinish
            )
            .buttonStyle(.secondary())
            .disabled(isApplying)
        }
        .frame(maxWidth: .infinity)
    }
}
