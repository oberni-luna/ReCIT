//
//  SortApplyLedger.swift
//  ReCIT_iOS
//
//  The apply run's ledger: one outcome per étagère the run writes to, and the reduction
//  the report is written from.
//
//  Pure because a partial failure makes its two questions load-bearing. *Is this
//  étagère done* decides which mark the sorting surface draws against it, and an
//  étagère whose shelf was created but whose books never landed must not be shown as
//  done — that half-truth is precisely what the waiting apply exists to rule out.
//  *Which étagères landed and which did not* is the report, and since nothing is rolled
//  back it is the only account the user gets of the real state of their library — an
//  account with three parts rather than two, because the étagère the run broke on may
//  exist without its books.
//
//  Declaration order is kept throughout, so the report names étagères in the order the
//  user was reading them rather than in whatever order a dictionary yields.
//
//  **An entry is keyed apart from its name.** The surface writes to étagères that
//  already exist as well as to drafted ones, and two of them may legitimately share a
//  name — the server does not enforce uniqueness — so a ledger keyed on the name would
//  collapse two rows into one and misreport which of them landed. It also has to
//  survive a draft becoming a real étagère mid-run, which changes the section's id but
//  not its name. So an entry carries a stable `key` beside the `name` the report reads
//  out.
//
//  It was `SortApplyLedger`, under `Model/AutoSort/`, and moved here when PRD 0008
//  retired the review screen it was written for: the vocabulary is unchanged — pending,
//  applying, landed, failed — and so is the reduction, but the only run that writes
//  anything is now the sorting surface's.
//
//  No store, no network, no SwiftUI. See PRD 0006 / PRD 0008.
//

import Foundation

struct SortApplyLedger: Equatable, Sendable {

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

    /// One étagère of the run: what identifies it while the run goes, and what the
    /// report calls it afterwards. On the sorting surface the two differ — a section's
    /// identity is its id, its name is user data — and they coincide only where a name
    /// is already canonical and unique.
    struct Entry: Equatable, Sendable {
        let key: String
        let name: String

        init(key: String, name: String) {
            self.key = key
            self.name = name
        }

        /// The étagère whose name *is* its identity.
        init(name: String) {
            self.init(key: name, name: name)
        }
    }

    /// The étagères of the run, in the order they will be written.
    let entries: [Entry]

    private var outcomes: [String: ShelfOutcome]

    /// Duplicates are collapsed on the way in, so `entries` and the outcome keys
    /// cannot disagree about how many étagères there are.
    init(entries: [Entry]) {
        var ordered: [Entry] = []
        var outcomes: [String: ShelfOutcome] = [:]
        for entry in entries where outcomes[entry.key] == nil {
            outcomes[entry.key] = .pending
            ordered.append(entry)
        }
        self.entries = ordered
        self.outcomes = outcomes
    }

    /// The étagères of the run, named, in the order they will be written.
    var shelfNames: [String] { entries.map(\.name) }

    /// An étagère the ledger does not know reads as `pending` rather than trapping:
    /// the list draws a mark per row, and a row it has no record of has plainly not
    /// been done.
    func outcome(for key: String) -> ShelfOutcome {
        outcomes[key] ?? .pending
    }

    /// Records an outcome. An étagère the ledger does not know is ignored — the ledger
    /// is built from the plan being applied, so an unknown key is a caller bug and
    /// inventing a row for it would put an étagère on screen that was never proposed.
    mutating func mark(_ outcome: ShelfOutcome, for key: String) {
        guard outcomes[key] != nil else { return }
        outcomes[key] = outcome
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
        entries.filter { outcome(for: $0.key) != .landed }.map(\.name)
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
        entries.filter { self.outcome(for: $0.key) == outcome }.map(\.name)
    }

    var isFinished: Bool {
        result != .running
    }
}
