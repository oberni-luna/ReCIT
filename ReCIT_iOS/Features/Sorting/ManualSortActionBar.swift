//
//  ManualSortActionBar.swift
//  ReCIT_iOS
//
//  The three controls at the foot of the sorting surface, on one line: throw the session
//  away, save it, or ask the phone for a proposal. In that order, per the design
//  (`161:6924`) — the destructive one furthest from the thumb's resting place, the primary
//  in the middle where it is unmissable.
//
//  **One line, not three.** PRD 0008 stacked three full-width buttons at the foot of a list;
//  the panel this now lives in is anchored, so every point it takes is a point the grid does
//  not get. Two round icon buttons and a pill do the same work in a third of the height.
//
//  **« Terminer » is gone.** It was the same button as « Annuler », relabelled when the stack
//  emptied — a rule that only made sense on a pushed screen where the button was also the
//  way out. The surface is a modal now: leaving is the close control, and the round discard
//  simply goes inert when there is nothing to discard, which says the same thing without a
//  word (PRD 0009).
//
//  **While a run owns the stack, all three stand down.** Discarding a stack halfway through
//  being written, or firing a second run on top of the first, would both destroy the account
//  of what landed. The writes themselves are owned by the session and carry on regardless of
//  this screen.
//
//  Icons carry text labels they do not display: a round button with no accessible name is a
//  button a screen reader cannot describe.
//

import SwiftUI

struct ManualSortActionBar: View {
    let actions: SortActions

    var body: some View {
        HStack(spacing: .sMedium) {
            Button("manual_sort.discard", systemImage: "arrow.uturn.backward", action: actions.onDiscard)
                .labelStyle(.iconOnly)
                .buttonStyle(.circularIcon)
                .disabled(actions.hasPendingChanges == false || actions.isBusy)

            Button("manual_sort.apply", action: actions.onApply)
                .buttonStyle(.primary())
                .disabled(actions.hasPendingChanges == false || actions.isBusy)
                .accessibilityIdentifier("e2e.sort.apply")

            ManualSortProposalButton(
                entryPoint: actions.entryPoint,
                isProposing: actions.isProposing,
                isApplying: actions.isApplying,
                onPropose: actions.onPropose
            )
        }
        .frame(maxWidth: .infinity)
    }
}
