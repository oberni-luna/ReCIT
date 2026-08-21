//
//  SortApplyLandingTests.swift
//  ReCIT_iOSTests
//
//  What the sorting surface looks like once part of a rangement has been written, and
//  what pressing the button a second time would send.
//
//  This is the slice's load-bearing rule: a failure halfway stops the run, keeps what
//  landed, and leaves the rest in the stack — so the pills, the recap and the button
//  labels go on telling the truth with no special case, and resuming repeats nothing.
//  Repeating is not a cosmetic bug: `add-items` is idempotent, but replaying a
//  creation that succeeded leaves the user with two étagères of the same name.
//
//  Pure and store-free. The runs below drive `SortApplyLanding` exactly as
//  `SortSessionModel` does — one landing per confirmed call — against a stub that hands
//  back an id for every creation and can be told to break at the *n*th call. What is
//  asserted is what the user would see and what the server would receive, never how the
//  reduction gets there.
//
//  See PRD 0008.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortApplyLanding")
struct SortApplyLandingTests {

    // MARK: - Fixtures

    private static func book(_ id: String) -> AutoSortBook {
        .init(id: id, title: "Livre \(id)")
    }

    /// Two étagères holding books, one empty étagère, and two books on none.
    private static let library: SortSnapshot = .init(
        shelves: [
            .init(id: "s1", name: "Romans classiques", bookIds: ["1", "2"]),
            .init(id: "s2", name: "Poésie", bookIds: ["3"]),
            .init(id: "s3", name: "Bandes dessinées", bookIds: [])
        ],
        books: [book("1"), book("2"), book("3"), book("4"), book("5")]
    )

    /// One apply, against a server that answers everything except — optionally — the
    /// *n*th call it is asked to make.
    ///
    /// It mirrors the run: the plan is reduced once, at the start, and each confirmed
    /// call is folded back in on its own, so a group that breaks after its creation
    /// leaves that creation out of the stack.
    private struct Run {
        var snapshot: SortSnapshot
        var changes: [SortChange]

        /// The names the server was asked to create, in order.
        private(set) var creations: [String] = []
        /// The `remove-items` calls, as (étagère id, books).
        private(set) var removals: [(shelf: String, books: [String])] = []
        /// The `add-items` calls, as (étagère id, books).
        private(set) var additions: [(shelf: String, books: [String])] = []

        private var calls: Int = 0

        init(snapshot: SortSnapshot, changes: [SortChange]) {
            self.snapshot = snapshot
            self.changes = changes
        }

        var plan: SortWritePlan {
            .init(snapshot: snapshot, changes: changes)
        }

        var projection: SortProjection {
            .init(snapshot: snapshot, changes: changes)
        }

        /// Runs the apply. `failingAtCall` counts every server call, creations
        /// included, from 1.
        ///
        /// - Returns: the names of the étagères the run got all the way through.
        @discardableResult
        mutating func apply(failingAtCall: Int? = nil) -> [String] {
            var landed: [String] = []

            for write in plan.operations {
                var shelfId: String
                switch write.section {
                case .shelf(let id): shelfId = id
                case .draft, .unshelved: shelfId = ""
                }

                if write.createsShelf {
                    guard case .draft(let draftId) = write.section else { continue }
                    calls += 1
                    guard calls != failingAtCall else { return landed }
                    creations.append(write.name)
                    shelfId = "server-\(creations.count)"
                    land(.shelfCreated(draftId: draftId, shelfId: shelfId, name: write.name))
                }

                if write.removals.isEmpty == false {
                    calls += 1
                    guard calls != failingAtCall else { return landed }
                    removals.append((shelfId, write.removals))
                    land(.booksRemoved(shelfId: shelfId, bookIds: write.removals))
                }

                if write.additions.isEmpty == false {
                    calls += 1
                    guard calls != failingAtCall else { return landed }
                    additions.append((shelfId, write.additions))
                    land(.booksAdded(shelfId: shelfId, bookIds: write.additions))
                }

                landed.append(write.name)
            }

            return landed
        }

        private mutating func land(_ confirmation: SortApplyLanding.Confirmation) {
            let landing: SortApplyLanding = .init(
                snapshot: snapshot,
                changes: changes,
                confirmed: confirmation
            )
            snapshot = landing.snapshot
            changes = landing.changes
        }
    }

    private func section(_ projection: SortProjection, named name: String) -> SortSection? {
        projection.sections.first { $0.name == name }
    }

    // MARK: - A run that finishes

    /// The end of a successful rangement: nothing left to save, so the recap goes
    /// quiet, the pills go out and the third button says « Terminer » — all of which
    /// this screen derives from the stack being empty.
    @Test("A rangement that goes through leaves nothing to save")
    func aCompleteRunEmptiesTheStack() {
        var run: Run = .init(
            snapshot: Self.library,
            changes: [
                .createShelf(draftId: "draft:sf", name: "Science-fiction"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft("draft:sf")),
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2"))
            ]
        )

        run.apply()

        #expect(run.changes.isEmpty)
        #expect(run.plan.hasWork == false)
        #expect(run.plan.hasPendingChanges == false)
        #expect(run.plan.status(of: .shelf("s1")) == .untouched)
        #expect(run.plan.status(of: .shelf("s2")) == .untouched)
    }

    /// And what it wrote is what the user arranged: the new étagère exists holding its
    /// book, and the book that moved is where it was dropped.
    @Test("A rangement that goes through leaves the library as the screen showed it")
    func aCompleteRunLandsTheArrangement() {
        var run: Run = .init(
            snapshot: Self.library,
            changes: [
                .createShelf(draftId: "draft:sf", name: "Science-fiction"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft("draft:sf")),
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2"))
            ]
        )

        run.apply()

        #expect(run.creations == ["Science-fiction"])
        #expect(section(run.projection, named: "Science-fiction")?.books.map(\.id) == ["4"])
        #expect(section(run.projection, named: "Romans classiques")?.books.map(\.id) == ["2"])
        // Snapshot order, not arrival order — and that is the point: the run emptied the
        // stack, so nothing is "moved" any more and the library reads as the server holds
        // it. Arrival order is a property of pending work only.
        #expect(section(run.projection, named: "Poésie")?.books.map(\.id) == ["1", "3"])
        #expect(run.projection.unshelved.books.map(\.id) == ["5"])
    }

    /// A draft the user left empty is created like any other, and the stack still empties
    /// afterwards — which is what the old dropped-draft rule was protecting: a creation
    /// that is never sent can never be confirmed, so it would sit in the stack forever.
    /// Sending it resolves that by the other end.
    @Test("A new étagère left empty is created, and the save still empties the stack")
    func anEmptyDraftIsCreatedByTheRun() {
        var run: Run = .init(
            snapshot: Self.library,
            changes: [
                .createShelf(draftId: "draft:essais", name: "Essais"),
                .moveBook(bookId: "4", from: .unshelved, to: .shelf("s3"))
            ]
        )

        #expect(run.plan.summary.shelvesToCreate == 1)

        run.apply()

        #expect(run.creations == ["Essais"])
        #expect(run.changes.isEmpty)
        #expect(section(run.projection, named: "Essais")?.books.isEmpty == true)
    }

    /// A book dragged about all afternoon costs the server one removal and one
    /// addition — the coalescing is `SortWritePlan`'s and is asserted there; what is
    /// asserted here is that the run sends that and no more.
    @Test("A book moved three times costs one removal and one addition")
    func aBookMovedThreeTimesIsWrittenOnce() {
        var run: Run = .init(
            snapshot: Self.library,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
                .moveBook(bookId: "1", from: .shelf("s2"), to: .unshelved),
                .moveBook(bookId: "1", from: .unshelved, to: .shelf("s3"))
            ]
        )

        run.apply()

        #expect(run.removals.count == 1)
        #expect(run.removals.first?.shelf == "s1")
        #expect(run.removals.first?.books == ["1"])
        #expect(run.additions.count == 1)
        #expect(run.additions.first?.shelf == "s3")
        #expect(run.additions.first?.books == ["1"])
    }

    // MARK: - A run that stops partway

    /// The heart of it. The run breaks on the second étagère; what it already wrote has
    /// left the stack, so what is left is exactly the work that did not happen — and
    /// the étagère that landed stops being marked as changed, on its own.
    @Test("After a stop, the stack holds exactly the work that did not land")
    func aStopLeavesOnlyTheUnlandedWork() {
        var run: Run = .init(
            snapshot: Self.library,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved),
                .moveBook(bookId: "4", from: .unshelved, to: .shelf("s3"))
            ]
        )

        // Call 1 is « Romans classiques » giving up its book; call 2 is « Bandes
        // dessinées » receiving one, and it never happens.
        run.apply(failingAtCall: 2)

        #expect(run.plan.status(of: .shelf("s1")) == .untouched)
        #expect(run.plan.status(of: .shelf("s3")) == .modified)
        #expect(run.plan.operations.count == 1)
        #expect(run.plan.operations.first?.section == .shelf("s3"))
        #expect(run.plan.operations.first?.additions == ["4"])
        #expect(run.plan.hasPendingChanges)
    }

    /// A move between two étagères is split across two groups, and each étagère takes
    /// books off before it puts books on. If the addition is what fails, the book falls
    /// back into « À ranger » — an honest intermediate state, and never a lost book —
    /// and the stack still holds the half that did not happen.
    @Test("A move whose addition fails leaves the book in À ranger, not nowhere")
    func aMoveThatBreaksBetweenItsHalvesLeavesTheBookInThePile() {
        var run: Run = .init(
            snapshot: Self.library,
            changes: [.moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2"))]
        )

        run.apply(failingAtCall: 2)

        // What the library now actually holds: the book left one étagère and never
        // reached the other, so it is on none — never on two, and never lost.
        let saved: SortProjection = .init(snapshot: run.snapshot)
        #expect(saved.unshelved.books.map(\.id).contains("1"))
        #expect(section(saved, named: "Romans classiques")?.books.map(\.id) == ["2"])
        #expect(section(saved, named: "Poésie")?.books.map(\.id) == ["3"])

        // And the half that did not happen is still on the screen, still pending.
        #expect(run.plan.operations.count == 1)
        #expect(run.plan.operations.first?.section == .shelf("s2"))
        #expect(run.plan.operations.first?.additions == ["1"])
        // "1" sits last: it has been moved, and a moved book lands at the foot of its
        // destination (see `SortProjection`).
        #expect(section(run.projection, named: "Poésie")?.books.map(\.id) == ["3", "1"])
    }

    /// The one that would cost the user a duplicate shelf. The creation landed and the
    /// books did not, so the étagère exists: what is left is a fill of an étagère that
    /// now exists, never a second creation of the same name.
    @Test("A creation that lands before the failure is never sent twice")
    func aCreationThatLandedIsNotReplayed() {
        var run: Run = .init(
            snapshot: Self.library,
            changes: [
                .createShelf(draftId: "draft:sf", name: "Science-fiction"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft("draft:sf")),
                .moveBook(bookId: "5", from: .unshelved, to: .draft("draft:sf"))
            ]
        )

        // Call 1 creates the étagère, call 2 files its books and fails.
        run.apply(failingAtCall: 2)

        #expect(run.creations == ["Science-fiction"])
        #expect(run.plan.operations.count == 1)
        #expect(run.plan.operations.first?.createsShelf == false)
        #expect(run.plan.operations.first?.additions == ["4", "5"])
        // It exists now, and its contents still differ — which is what « Modifiée »
        // says. No special case was needed to get there.
        #expect(run.plan.status(of: .shelf("server-1")) == .modified)

        run.apply()

        #expect(run.creations == ["Science-fiction"])
        #expect(run.changes.isEmpty)
    }

    /// Pressing the button again finishes the rangement, and the server hears about
    /// each piece of work exactly once across the two attempts.
    @Test("Applying again after a stop finishes the job without repeating anything")
    func resumingFinishesWithoutRepeating() {
        let changes: [SortChange] = [
            .createShelf(draftId: "draft:sf", name: "Science-fiction"),
            .moveBook(bookId: "4", from: .unshelved, to: .draft("draft:sf")),
            .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
            .moveBook(bookId: "3", from: .shelf("s2"), to: .unshelved)
        ]

        var straightThrough: Run = .init(snapshot: Self.library, changes: changes)
        straightThrough.apply()

        var interrupted: Run = .init(snapshot: Self.library, changes: changes)
        interrupted.apply(failingAtCall: 3)
        #expect(interrupted.changes.isEmpty == false)
        interrupted.apply()

        #expect(interrupted.changes.isEmpty)
        #expect(interrupted.creations == straightThrough.creations)
        #expect(interrupted.removals.map(\.books) == straightThrough.removals.map(\.books))
        #expect(interrupted.additions.map(\.books) == straightThrough.additions.map(\.books))
        // And the library it leaves behind is the one the user arranged, whichever way
        // it got there.
        #expect(interrupted.snapshot == straightThrough.snapshot)
    }

    /// Nothing at all landed, so nothing at all leaves the stack: the second press has
    /// the whole rangement still to do.
    @Test("A run that fails on its very first call leaves the stack untouched")
    func aRunThatFailsImmediatelyChangesNothing() {
        let changes: [SortChange] = [
            .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2"))
        ]
        var run: Run = .init(snapshot: Self.library, changes: changes)

        run.apply(failingAtCall: 1)

        #expect(run.snapshot == Self.library)
        #expect(run.plan.operations.count == 2)
        #expect(run.plan.status(of: .shelf("s1")) == .modified)
        #expect(run.plan.status(of: .shelf("s2")) == .modified)
    }
}
