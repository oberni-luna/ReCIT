//
//  SortFooter.swift
//  ReCIT_iOS
//
//  What the line under the buttons says, and the rule that decides which of its readings is
//  on screen. One slot, four readings — the sorting surface's footer is an *emplacement*,
//  not a sentence, and it grows upward against the grid when it has more to say (PRD 0009).
//
//  The order of the cases is the rule: a finished run's account outranks the recap, because
//  the recap in the present tense next to a report in the past tense reads as a screen
//  contradicting itself; and a notice — « aucun rangement à proposer » — outranks both,
//  because it answers a button the user has just pressed and there is no SnackBar above a
//  full-screen cover to say it instead.
//
//  **The recap doubles as the progress.** It is derived from `SortWritePlan`, and the plan
//  shrinks as each confirmed write leaves the stack — so while a run is in flight the recap
//  counts itself down. No « n sur m » string, no second counter, and no way for the two to
//  disagree, which is the same argument as PRD 0008's "one reduction, three readings".
//

import Foundation

enum SortFooter: Equatable {
    /// Nothing pending and nothing done: an empty stack has nothing to recap.
    case silent
    /// What saving would do — and, during a run, what is left of it.
    case recap(SortWritePlan)
    /// What a settled run did, in full: all landed, nothing to save, or the three-part
    /// account of a run that stopped partway.
    case report(SortApplyLedger)
    /// One sentence answering something the user just pressed.
    case notice(SortNotice)

    /// The reading the screen is owed, given the session's state.
    init(
        plan: SortWritePlan,
        progress: SortApplyLedger?,
        notice: SortNotice?
    ) {
        if let notice {
            self = .notice(notice)
        } else if let progress, progress.isFinished {
            self = .report(progress)
        } else if plan.hasPendingChanges {
            self = .recap(plan)
        } else {
            self = .silent
        }
    }
}

/// The one-off things the footer has to say, kept as a type so a caller cannot invent copy
/// at a call site. They live here rather than in the error reporter because the SnackBar it
/// feeds is owned by `MainTabView` and does not draw above this screen's cover — a failure
/// the sorting surface answers by stating its own outcomes (PRD 0009).
enum SortNotice: Equatable {
    /// The model was asked and had nothing to add. From the far side of a wait the user
    /// triggered, a screen that does not change is indistinguishable from a broken button.
    case nothingToPropose
}
