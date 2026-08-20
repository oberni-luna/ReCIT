//
//  ManualSortApplyLedgerTests.swift
//  ReCIT_iOSTests
//
//  The apply ledger as the sorting surface uses it: one row per étagère the run writes
//  to, identified by the section rather than by the name it happens to carry.
//
//  It earns its own suite beside `SortApplyLedgerTests` because the questions are not
//  the same ones. That one asks the questions the retired auto-sort run asked, where a
//  run only ever created étagères whose names had been canonicalised and deduplicated
//  before the ledger saw them. This one writes to étagères the user already owns — whose
//  names the server never promised to keep unique — and to drafts whose section id
//  changes the moment they are created. A ledger that collapsed two rows, or lost one
//  when a draft became real, would misreport what the user's library now contains, and
//  nothing is rolled back to soften it.
//
//  Pure and store-free: a ledger is a value, and these are sentences about it.
//
//  See PRD 0008.
//

import Testing
@testable import ReCIT_iOS

@Suite("ManualSortApplyLedger")
struct ManualSortApplyLedgerTests {

    private let entries: [SortApplyLedger.Entry] = [
        .init(key: "shelf:s1", name: "Romans classiques"),
        .init(key: "draft:sf", name: "Science-fiction"),
        .init(key: "shelf:s3", name: "Bandes dessinées")
    ]

    @Test("A fresh ledger has every étagère still to write")
    func freshLedgerIsAllPending() {
        let progress: SortApplyLedger = .init(entries: entries)

        #expect(progress.shelfNames == ["Romans classiques", "Science-fiction", "Bandes dessinées"])
        #expect(entries.allSatisfy { progress.outcome(for: $0.key) == .pending })
        #expect(progress.result == .running)
    }

    /// The reason the row is not keyed on the name: two étagères may be called the same
    /// thing, and each of them has to be able to succeed or fail on its own.
    @Test("Two étagères that share a name are two rows, and one can land without the other")
    func twoShelvesSharingANameStayApart() {
        var progress: SortApplyLedger = .init(
            entries: [
                .init(key: "shelf:s1", name: "Lectures"),
                .init(key: "shelf:s2", name: "Lectures")
            ]
        )

        progress.mark(.landed, for: "shelf:s1")
        progress.mark(.failed, for: "shelf:s2")

        #expect(progress.shelfNames == ["Lectures", "Lectures"])
        #expect(progress.landedNames == ["Lectures"])
        #expect(progress.failedNames == ["Lectures"])
        #expect(progress.result == .stopped(
            landed: ["Lectures"],
            failed: ["Lectures"],
            notAttempted: []
        ))
    }

    /// A tick means the whole of that étagère's share landed. An étagère brought into
    /// existence and then left empty by a failed membership write is a failure, and the
    /// report has to say so apart from the ones nobody touched — it is sitting in the
    /// user's carousel.
    @Test("An étagère created but not filled is reported as failed, not as never created")
    func createdButNotFilledIsAFailure() {
        var progress: SortApplyLedger = .init(entries: entries)

        progress.mark(.landed, for: "shelf:s1")
        progress.mark(.applying, for: "draft:sf")
        progress.mark(.failed, for: "draft:sf")

        #expect(progress.outcome(for: "draft:sf") == .failed)
        #expect(progress.landedNames == ["Romans classiques"])
        #expect(progress.failedNames == ["Science-fiction"])
        #expect(progress.notAttemptedNames == ["Bandes dessinées"])
        #expect(progress.result == .stopped(
            landed: ["Romans classiques"],
            failed: ["Science-fiction"],
            notAttempted: ["Bandes dessinées"]
        ))
    }

    /// The account names étagères, not the ids the run identifies them by: the user
    /// reads « Science-fiction », never `draft:sf`.
    @Test("The account of a run names étagères the way the user does")
    func theAccountReadsInNames() {
        var progress: SortApplyLedger = .init(entries: entries)

        for entry in entries {
            progress.mark(.landed, for: entry.key)
        }

        #expect(progress.landedNames == ["Romans classiques", "Science-fiction", "Bandes dessinées"])
        #expect(progress.result == .allLanded)
    }

    /// A rangement whose gestures cancelled each other out is a finished run with
    /// nothing in it — which the report has to be able to say without claiming that
    /// zero étagères were saved.
    @Test("A run with nothing to write is finished, with nothing landed")
    func anEmptyRunIsFinishedAndEmpty() {
        let progress: SortApplyLedger = .init(entries: [])

        #expect(progress.result == .allLanded)
        #expect(progress.isFinished)
        #expect(progress.landedCount == 0)
        #expect(progress.shelfNames.isEmpty)
    }

    /// Marks are still keyed by identity when a run is only halfway down the list, so
    /// the étagères below the one being written read as pending and none of them shows
    /// a tick it has not earned.
    @Test("A run partway down the list has landed, applying and pending rows at once")
    func partwayThroughReadsThreeWays() {
        var progress: SortApplyLedger = .init(entries: entries)

        progress.mark(.landed, for: "shelf:s1")
        progress.mark(.applying, for: "draft:sf")

        #expect(progress.outcome(for: "shelf:s1") == .landed)
        #expect(progress.outcome(for: "draft:sf") == .applying)
        #expect(progress.outcome(for: "shelf:s3") == .pending)
        #expect(progress.result == .running)
        #expect(progress.isFinished == false)
    }
}
