//
//  SortFooter.swift
//  ReCIT_iOS
//
//  What the line under the buttons says, and the rule that decides which of its readings is
//  on screen. One slot, several readings — the sorting surface's footer is an *emplacement*,
//  not a sentence, and it grows upward against the grid when it has more to say (PRD 0009).
//
//  **The slot is never empty.** A session nobody has touched yet used to render nothing, so
//  the panel was shorter before the first drag than after it and the buttons moved down the
//  moment anything was done. `idle` says there is nothing to save, and that is now all it
//  says: the instruction it used to open with is SORT-1's, said once, at the first opening,
//  pointing at the book it talks about rather than standing under the buttons for someone who
//  has filed two hundred (PRD 0013). The one collection where it stays written is the one with
//  no étagère at all — `idleWithoutShelves` (design `160:6659` / `185:7804`).
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
    /// Nothing pending and nothing done. Not silence, but not an instruction either: the one
    /// reading that has no numbers in it says only that there is nothing to save, because the
    /// astuce says the gesture better — once, and aimed at a book.
    case idle
    /// The same state, on a collection that has no étagère at all. Here the instruction stays:
    /// SORT-1 points at a book to drag, and a book with nowhere to land teaches nothing — so
    /// the one reader the astuce cannot serve is the one who keeps it in writing.
    case idleWithoutShelves
    /// What saving would do — and, during a run, what is left of it.
    case recap(SortWritePlan)
    /// What a settled run did, in full: all landed, nothing to save, or the three-part
    /// account of a run that stopped partway.
    case report(SortApplyLedger)
    /// One sentence answering something the user just pressed.
    case notice(SortNotice)

    /// The reading the screen is owed, given the session's state.
    ///
    /// `hasShelves` only ever separates the two idle readings: with something to save or
    /// something to report, what the screen owes is that, whether or not there is an étagère
    /// to put a book on.
    init(
        plan: SortWritePlan,
        progress: SortApplyLedger?,
        notice: SortNotice?,
        hasShelves: Bool
    ) {
        if let notice {
            self = .notice(notice)
        } else if let progress, progress.isFinished {
            self = .report(progress)
        } else if plan.hasPendingChanges {
            self = .recap(plan)
        } else if hasShelves {
            self = .idle
        } else {
            self = .idleWithoutShelves
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
