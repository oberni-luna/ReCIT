//
//  SortApplyLedgerTests.swift
//  ReCIT_iOSTests
//
//  The apply run's ledger, and the property the apply's recovery story rests on. Pure
//  and network-free, like the other three auto-sort suites: no model, no store, no
//  SwiftUI, no `LanguageModelSession`.
//
//  Why this earns a suite when the rest of issue 0024 is orchestration: nothing is
//  rolled back when a run stops partway, so the ledger's reduction *is* the user's only
//  account of what their library now contains. A tick against an étagère that was never
//  filled, or a "not created" naming an étagère that was, is a lie about their data —
//  the same class of failure the waiting apply exists to prevent, and not one a build
//  will catch.
//
//  The last test pins the re-run property rather than the ledger: because a plan is only
//  ever built from books on no étagère, everything a partial run filed has stopped being
//  a candidate, so running again cannot duplicate it. See PRD 0006.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortApplyLedger")
struct SortApplyLedgerTests {

    private let names: [String] = ["Imaginaire", "Policiers", "Essais"]

    private func book(_ id: String, genres: [String] = []) -> AutoSortBook {
        .init(id: id, title: "Livre \(id)", genres: genres)
    }

    // MARK: - Before the run

    @Test("A fresh ledger has every étagère still to create, and the run reads as running")
    func freshLedgerIsAllPending() {
        let progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        #expect(progress.shelfNames == names)
        #expect(names.allSatisfy { progress.outcome(for: $0) == .pending })
        #expect(progress.result == .running)
        #expect(progress.isFinished == false)
        #expect(progress.landedCount == 0)
    }

    @Test("An étagère the ledger never heard of reads as pending rather than trapping")
    func unknownShelfReadsAsPending() {
        let progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        #expect(progress.outcome(for: "Bandes dessinées") == .pending)
    }

    @Test("Marking an étagère the ledger never heard of adds no row")
    func markingAnUnknownShelfIsIgnored() {
        var progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        progress.mark(.landed, for: "Bandes dessinées")

        #expect(progress.shelfNames == names)
        #expect(progress.landedNames.isEmpty)
        #expect(progress.outcome(for: "Bandes dessinées") == .pending)
    }

    @Test("A repeated name is one étagère, not two")
    func duplicateNamesCollapse() {
        let progress: SortApplyLedger = .init(entries: ["Imaginaire", "Policiers", "Imaginaire"].map { .init(name: $0) })

        #expect(progress.shelfNames == ["Imaginaire", "Policiers"])
    }

    // MARK: - A run that finishes

    @Test("A run in progress stays running until the last étagère has landed")
    func partwayThroughIsStillRunning() {
        var progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        progress.mark(.landed, for: "Imaginaire")
        progress.mark(.applying, for: "Policiers")

        #expect(progress.result == .running)
        #expect(progress.isFinished == false)
        #expect(progress.landedNames == ["Imaginaire"])
    }

    @Test("Every étagère landed is a finished run with nothing left out")
    func allLanded() {
        var progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        for name in names {
            progress.mark(.landed, for: name)
        }

        #expect(progress.result == .allLanded)
        #expect(progress.isFinished)
        #expect(progress.landedCount == 3)
        #expect(progress.notLandedNames.isEmpty)
    }

    @Test("An empty plan is a finished run, not a stalled one")
    func emptyLedgerIsFinished() {
        let progress: SortApplyLedger = .init(entries: [])

        #expect(progress.result == .allLanded)
        #expect(progress.isFinished)
    }

    // MARK: - A run that stops partway

    /// The report's whole job. What landed is kept, so the account is in three parts:
    /// what exists and is filled, where the run broke — which may exist empty, since
    /// nothing is rolled back — and what was never touched. Order is review order in all
    /// three, so the user can follow it down the list they just approved.
    @Test("A failure partway splits the étagères into landed, failed and never attempted")
    func failurePartwaySplitsThreeWays() {
        var progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        progress.mark(.landed, for: "Imaginaire")
        progress.mark(.failed, for: "Policiers")

        #expect(progress.result == .stopped(
            landed: ["Imaginaire"],
            failed: ["Policiers"],
            notAttempted: ["Essais"]
        ))
        #expect(progress.isFinished)
        #expect(progress.landedCount == 1)
        #expect(progress.notLandedNames == ["Policiers", "Essais"])
    }

    @Test("A first étagère failing reports nothing created and filled")
    func failureOnTheFirstShelfReportsNothingCreated() {
        var progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        progress.mark(.failed, for: "Imaginaire")

        #expect(progress.result == .stopped(
            landed: [],
            failed: ["Imaginaire"],
            notAttempted: ["Policiers", "Essais"]
        ))
        #expect(progress.landedCount == 0)
    }

    /// The failed étagère is never folded into "not created": it is the one shelf that
    /// may exist without its books, and a report that hid that would send the user
    /// looking for something already in their carousel.
    @Test("The étagère the run broke on is reported apart from the ones never attempted")
    func failedShelfIsReportedApartFromTheUntouchedOnes() {
        var progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        progress.mark(.landed, for: "Imaginaire")
        progress.mark(.failed, for: "Policiers")

        #expect(progress.failedNames == ["Policiers"])
        #expect(progress.notAttemptedNames == ["Essais"])
    }

    /// A shelf created but never filled is a failure, not a partial success: the tick
    /// means both stages landed or it means nothing.
    @Test("An étagère whose membership write failed is not counted as created")
    func createdButUnfilledIsNotLanded() {
        var progress: SortApplyLedger = .init(entries: names.map { .init(name: $0) })

        progress.mark(.applying, for: "Imaginaire")
        progress.mark(.failed, for: "Imaginaire")

        #expect(progress.outcome(for: "Imaginaire") == .failed)
        #expect(progress.landedNames.isEmpty)
    }

    // MARK: - Re-running after a partial failure

    /// The reason the scope is unshelved-only. The run below files the first étagère and
    /// fails on the second; the second plan is built from the books that are *still* on
    /// no étagère — which the app reads off `InventoryItem.shelves` and which is
    /// reproduced here by dropping the books the first run filed — and it proposes only
    /// the étagère that never landed. No duplicate, and no second copy of a filed book.
    @Test("Re-running after a partial failure proposes only what is still unshelved")
    func reRunningProposesOnlyWhatIsStillUnshelved() throws {
        let taxonomy: [String] = ["Imaginaire", "Policiers"]
        let mapping: ValidatedGenreMapping = try ShelfMappingValidator.validate(
            taxonomy: taxonomy,
            assignments: [
                .init(genre: "science-fiction", shelfName: "Imaginaire"),
                .init(genre: "roman policier", shelfName: "Policiers")
            ],
            offeredGenres: ["science-fiction", "roman policier"]
        )
        let books: [AutoSortBook] = [
            book("1", genres: ["science-fiction"]),
            book("2", genres: ["science-fiction"]),
            book("3", genres: ["roman policier"]),
            book("4", genres: ["roman policier"])
        ]

        let firstPlan: AutoSortPlan = .init(mapping: mapping, books: books)
        #expect(firstPlan.shelves.map(\.name) == ["Imaginaire", "Policiers"])

        var progress: SortApplyLedger = .init(entries: firstPlan.shelves.map { .init(name: $0.name) })
        progress.mark(.landed, for: "Imaginaire")
        progress.mark(.failed, for: "Policiers")

        let filed: Set<String> = .init(
            firstPlan.shelves
                .filter { progress.outcome(for: $0.name) == .landed }
                .flatMap(\.books)
                .map(\.id)
        )
        let stillUnshelved: [AutoSortBook] = books.filter { !filed.contains($0.id) }

        let secondPlan: AutoSortPlan = .init(mapping: mapping, books: stillUnshelved)

        #expect(secondPlan.shelves.map(\.name) == ["Policiers"])
        #expect(secondPlan.shelves[0].books.map(\.id) == ["3", "4"])
        #expect(secondPlan.shelvedBookCount == 2)
    }

    /// And once the run has finished cleanly there is nothing left to propose, so a
    /// re-run cannot recreate the étagères it just made.
    @Test("Re-running after a complete run has nothing left to propose")
    func reRunningAfterACompleteRunProposesNothing() throws {
        let mapping: ValidatedGenreMapping = try ShelfMappingValidator.validate(
            taxonomy: ["Imaginaire"],
            assignments: [.init(genre: "science-fiction", shelfName: "Imaginaire")],
            offeredGenres: ["science-fiction"]
        )
        let books: [AutoSortBook] = [book("1", genres: ["science-fiction"])]

        let firstPlan: AutoSortPlan = .init(mapping: mapping, books: books)
        var progress: SortApplyLedger = .init(entries: firstPlan.shelves.map { .init(name: $0.name) })
        progress.mark(.landed, for: "Imaginaire")
        #expect(progress.result == .allLanded)

        let secondPlan: AutoSortPlan = .init(mapping: mapping, books: [])

        #expect(secondPlan.isEmpty)
        #expect(secondPlan.shelvedBookCount == 0)
    }
}
