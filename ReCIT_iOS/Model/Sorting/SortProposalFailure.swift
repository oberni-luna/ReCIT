//
//  SortProposalFailure.swift
//  ReCIT_iOS
//
//  Why asking the on-device model for a rangement added nothing.
//
//  Stated rather than swallowed. The proposal lands as changes on a stack, so a run
//  that produces none leaves the screen exactly as it was — which, from the far side of
//  a wait the user triggered themselves, is indistinguishable from a broken button.
//  Every reason it can happen collapses to the same sentence, because they collapse to
//  the same fact for the user: the books left to file carry no genre the model could
//  work with, or everything it suggested is already where it suggested putting it.
//
//  It travels the shared `AppErrorReporter` channel, like every other thing this screen
//  has to say out loud (ADR 0001) — it is an outcome rather than a fault, but it is the
//  outcome of a button press and belongs where the user is looking.
//

import Foundation

enum SortProposalFailure: LocalizedError {

    /// The run finished and had nothing to add to the stack.
    case nothingToPropose

    var errorDescription: String? {
        switch self {
        case .nothingToPropose:
            String(localized: "manual_sort.proposal.nothing_proposed")
        }
    }
}
