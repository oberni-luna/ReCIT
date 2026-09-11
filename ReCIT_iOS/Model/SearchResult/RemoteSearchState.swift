//
//  RemoteSearchState.swift
//  ReCIT_iOS
//
//  What the inventaire.io half of the search surface is doing: nothing yet, waiting for an
//  answer, holding one, or having failed to get one. Pure — no SwiftUI, no SwiftData fetch —
//  so the rule can be driven by values in a test instead of by a network.
//
//  **It exists to keep three things apart that a screen confuses for free**: "it is loading",
//  "there is nothing" and "it did not work". Written as three booleans on a view — `isLoading`,
//  `results.isEmpty`, `hasFailed` — any two of them can be true at once, and the screen that
//  reads them then has to decide which wins, in each of the places it draws. `sign` answers
//  that once and returns **at most one** of the three: a state cannot be loading and empty, and
//  a failure cannot look like an empty library. That is the whole point of the type; the views
//  are the cheap part.
//
//  `.loaded([])` is a real answer — inventaire.io said "nothing" — and it is deliberately not
//  the same value as `.idle`, where nothing was ever asked. The distinction is exactly the one
//  a user reads as "no result" versus "not loaded".
//
//  See issue 0076 and PRD 0012.
//

import Foundation

enum RemoteSearchState: Equatable {
    /// Nothing has been sent, or what was sent no longer matches the field. The remote half of
    /// the screen says nothing at all.
    case idle
    /// A call has left and has not come back.
    case loading
    /// inventaire.io answered. Empty is an answer.
    case loaded([SearchResult])
    /// The call failed. What went wrong is told by `AppErrorReporter`; this only remembers
    /// *that* it did, so the screen can say so and offer to try again.
    case failed

    /// What the screen says in place of results — and never more than one of them at a time.
    enum Sign: Equatable {
        /// A visible sign that the call is running.
        case loading
        /// The query went out and came back with nothing.
        case noResult
        /// The call did not go through, and can be run again.
        case failure
    }

    /// The one thing to say right now, or `nil` when there are results to draw instead (or
    /// nothing to say at all).
    var sign: Sign? {
        switch self {
        case .idle:
            nil
        case .loading:
            .loading
        case .loaded(let results):
            results.isEmpty ? .noResult : nil
        case .failed:
            .failure
        }
    }

    /// The results to draw. Empty in every state but a non-empty answer, so a failure or a
    /// call in flight can never leave the previous query's results under the new one's sign.
    var results: [SearchResult] {
        guard case .loaded(let results) = self else { return [] }

        return results
    }
}
