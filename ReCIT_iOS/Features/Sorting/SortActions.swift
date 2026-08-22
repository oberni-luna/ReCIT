//
//  SortActions.swift
//  ReCIT_iOS
//
//  The three controls of the sorting surface, as one value: what each one does, and the
//  session state that decides whether it can be pressed.
//
//  It exists so the action bar takes one parameter instead of seven, and so the rules the
//  bar renders — a discard that is inert with an empty stack, everything standing down while
//  a run owns it — are stated once, here, rather than repeated in each button's `disabled`.
//

import Foundation

struct SortActions {

    /// The one input the discard control is derived from. **No "has applied" flag anywhere**:
    /// a successful apply empties the stack, so the control goes inert by itself, and taking
    /// sorting up again makes it live because there is once more something to discard.
    let hasPendingChanges: Bool

    /// What auto-sort's availability makes of the proposal control. Derived by the caller in
    /// its body, so flipping Apple Intelligence on re-renders it live.
    let entryPoint: AutoSortEntryPoint

    let isProposing: Bool
    let isApplying: Bool

    let onDiscard: () -> Void
    let onApply: () -> Void
    let onPropose: () -> Void

    /// Whether a run of either kind owns the stack. One question rather than two, so a guard
    /// cannot be written for the apply and forgotten for the proposal — the same reasoning as
    /// `SortSessionModel.isBusy`, which is where this comes from.
    var isBusy: Bool { isApplying || isProposing }
}
