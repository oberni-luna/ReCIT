//
//  AutoSortApplyProgress.swift
//  ReCIT_iOS
//
//  The apply run's ledger: one outcome per proposed étagère, and the reduction the
//  report is written from.
//
//  Pure because a partial failure makes its two questions load-bearing. *Is this
//  étagère done* decides which mark the review-turned-progress list draws against
//  it, and an étagère whose shelf was created but whose books never landed must not
//  be shown as done — that half-truth is precisely what the waiting apply exists to
//  rule out. *Which étagères were created and which were not* is the report, and since
//  nothing is rolled back it is the only account the user gets of the real state of
//  their library — an account with three parts rather than two, because the étagère the
//  run broke on may exist without its books.
//
//  Declaration order is kept throughout, so the report names étagères in the order
//  the user reviewed them rather than in whatever order a dictionary yields.
//
//  Keyed on the étagère's name, which is also `AutoSortPlan.ProposedShelf.id`: the
//  validated mapping canonicalises names and deduplicates them, so within one plan a
//  name identifies a shelf.
//
//  No store, no network, no SwiftUI. See PRD 0006.
//

import Foundation

struct AutoSortApplyProgress: Equatable, Sendable {

    /// How far one étagère has got. `landed` means *both* stages landed — the shelf
    /// exists on the server and its books are on it — because the whole point of
    /// waiting is that a tick can be trusted.
    enum ShelfOutcome: Equatable, Sendable {
        /// Not attempted. Either the run has not reached it, or it stopped before it.
        case pending
        case applying
        case landed
        case failed
    }

    /// Where the run as a whole stands. Reduced rather than tracked separately so it
    /// can never disagree with the marks on screen.
    enum Result: Equatable, Sendable {
        case running
        case allLanded
        /// Stopped partway, with nothing rolled back — so the account has to be in three
        /// parts rather than two. `landed` exists and holds its books. `failed` is where
        /// the run broke, and is the one case that cannot be described as either created
        /// or not: its shelf may exist, empty, if it was the membership write that failed
        /// rather than the creation. `notAttempted` was never touched at all.
        ///
        /// Collapsing `failed` into "not created" would have been the tidier report and
        /// the dishonest one: the user would go looking for an étagère that is sitting in
        /// their carousel.
        case stopped(landed: [String], failed: [String], notAttempted: [String])
    }

    /// The proposed étagères, in the order phase 1 declared them.
    let shelfNames: [String]

    private var outcomes: [String: ShelfOutcome]

    /// Duplicates are collapsed on the way in, so `shelfNames` and the outcome keys
    /// cannot disagree about how many étagères there are.
    init(shelfNames: [String]) {
        var ordered: [String] = []
        var outcomes: [String: ShelfOutcome] = [:]
        for name in shelfNames where outcomes[name] == nil {
            outcomes[name] = .pending
            ordered.append(name)
        }
        self.shelfNames = ordered
        self.outcomes = outcomes
    }

    /// A name the ledger does not know reads as `pending` rather than trapping: the
    /// list draws a mark per row, and a row it has no record of has plainly not been
    /// done.
    func outcome(for shelfName: String) -> ShelfOutcome {
        outcomes[shelfName] ?? .pending
    }

    /// Records an outcome. A name the ledger does not know is ignored — the ledger is
    /// built from the plan being applied, so an unknown name is a caller bug and
    /// inventing a row for it would put an étagère on screen that was never proposed.
    mutating func mark(_ outcome: ShelfOutcome, for shelfName: String) {
        guard outcomes[shelfName] != nil else { return }
        outcomes[shelfName] = outcome
    }

    /// The étagères that exist and hold their books, in review order.
    var landedNames: [String] {
        names(matching: .landed)
    }

    /// Where the run broke. At most one, since the run stops there — an array only
    /// because the reduction has no business assuming that.
    var failedNames: [String] {
        names(matching: .failed)
    }

    /// The étagères the run never got to, in review order.
    var notAttemptedNames: [String] {
        names(matching: .pending)
    }

    /// Everything that did not land, however it did not land — which is what decides
    /// whether the run is over. The report deliberately does *not* use it: a failed
    /// étagère may exist empty, so lumping it in with the untouched ones would misstate
    /// what the user owns.
    var notLandedNames: [String] {
        shelfNames.filter { outcome(for: $0) != .landed }
    }

    var landedCount: Int { landedNames.count }

    /// An empty ledger is `allLanded`, not `running`: there was nothing to create and
    /// nothing failed, which is a finished run.
    var result: Result {
        let failed: [String] = failedNames
        if failed.isEmpty == false {
            return .stopped(landed: landedNames, failed: failed, notAttempted: notAttemptedNames)
        }
        if notLandedNames.isEmpty {
            return .allLanded
        }
        return .running
    }

    private func names(matching outcome: ShelfOutcome) -> [String] {
        shelfNames.filter { self.outcome(for: $0) == outcome }
    }

    var isFinished: Bool {
        result != .running
    }
}
