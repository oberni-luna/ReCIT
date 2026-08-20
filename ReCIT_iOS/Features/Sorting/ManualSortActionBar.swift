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
//  for the duration: discarding a stack that is halfway through being written, or firing
//  a second run on top of the first, would both destroy the account of what landed. The
//  writes themselves are owned by the session and carry on regardless of this screen.
//
//  **« Proposer un rangement » sits first**, and it is the only one of the three that is
//  live on arrival: with an empty stack the primary is inert and the third is a way out,
//  so leading with the two dead buttons would put the one useful control last. On a
//  device that can never run the model the button is absent and the reason takes its
//  place — a control that does nothing is worse than none, but a silence is worse than
//  either, since this surface is where the empty-shelf card leads on every device. What
//  decides all of that is `ManualSortProposalButton`, which owns the three
//  unavailability states.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortActionBar: View {

    /// The one input the two stack buttons are derived from.
    let hasPendingChanges: Bool

    /// What auto-sort's availability makes of the proposal button. Derived by the caller
    /// in its body, so flipping Apple Intelligence on re-renders it live.
    let entryPoint: AutoSortEntryPoint

    /// Whether the model is working out a proposal right now.
    let isProposing: Bool

    /// Whether a run is writing right now. It disables rather than relabels: what the
    /// buttons would say is still true, they are simply not offered.
    let isApplying: Bool

    let onPropose: () -> Void
    let onApply: () -> Void
    let onDiscard: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: .medium) {
            ManualSortProposalButton(
                entryPoint: entryPoint,
                isProposing: isProposing,
                isApplying: isApplying,
                onPropose: onPropose
            )

            Button("manual_sort.apply", action: onApply)
                .buttonStyle(.primary())
                .disabled(hasPendingChanges == false || isApplying || isProposing)

            Button(
                hasPendingChanges ? "manual_sort.discard" : "manual_sort.finish",
                action: hasPendingChanges ? onDiscard : onFinish
            )
            .buttonStyle(.secondary())
            .disabled(isApplying || isProposing)
        }
        .frame(maxWidth: .infinity)
    }
}
