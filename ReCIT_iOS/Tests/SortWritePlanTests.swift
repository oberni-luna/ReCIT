//
//  SortWritePlanTests.swift
//  ReCIT_iOSTests
//
//  What applying would do, and what the screen says it would do — asserted as one
//  thing, because they are one reduction. A pill that marks an étagère « Modifiée »
//  while the write leaves it alone, or a recap promising two new shelves while one is
//  dropped, is the screen lying to a user about their own library.
//
//  Pure and store-free: `SortWritePlan` takes two value types and answers three
//  questions about them, which is exactly why PRD 0008 freezes the snapshot.
//
//  Each test states an external behaviour — given this library and these gestures,
//  this is what gets written, this is what the pill says, this is what the sentence
//  reads. None of them reaches into how the reduction gets there.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortWritePlan")
struct SortWritePlanTests {

    private func book(_ id: String) -> AutoSortBook {
        .init(id: id, title: "Livre \(id)")
    }

    private func shelf(_ id: String, _ name: String, _ bookIds: [String]) -> SortSnapshot.Shelf {
        .init(id: id, name: name, bookIds: bookIds)
    }

    /// The library the fixtures below sort: two étagères with books on them, one empty
    /// étagère, and two books on none.
    private var library: SortSnapshot {
        .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1", "2"]),
                shelf("s2", "Poésie", ["3"]),
                shelf("s3", "Bandes dessinées", [])
            ],
            books: [book("1"), book("2"), book("3"), book("4"), book("5")]
        )
    }

    private func operation(
        _ plan: SortWritePlan,
        for section: SortSection.ID
    ) -> SortWritePlan.ShelfWrite? {
        plan.operations.first { $0.section == section }
    }

    // MARK: - Nothing done, and work that undoes itself

    /// Nothing has been dragged: nothing to write, nothing to say, and the apply
    /// button — whose rule is the stack being non-empty — is inert.
    @Test func anEmptyStackWritesNothingAndRecapsNothing() {
        let plan: SortWritePlan = .init(snapshot: library)

        #expect(plan.hasPendingChanges == false)
        #expect(plan.hasWork == false)
        #expect(plan.operations.isEmpty)
        #expect(plan.status(of: .shelf("s1")) == .untouched)
        #expect(plan.status(of: .shelf("s2")) == .untouched)
        #expect(plan.status(of: .shelf("s3")) == .untouched)
        #expect(plan.summary.shelvesToCreate == 0)
        #expect(plan.summary.shelvesModified == 0)
        #expect(plan.summary.booksFiled == 0)
        #expect(plan.summary.booksLeftUnshelved == 2)
    }

    /// A book dragged out of an étagère and put back leaves a stack behind it — so the
    /// buttons still offer to save and to discard — but there is nothing to write and
    /// the étagère is not marked as changed. The marks describe reality, not
    /// hesitation.
    @Test func aBookDraggedOutOfAnEtagereAndBackLeavesNothingToWriteAndNoPill() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved),
                .moveBook(bookId: "1", from: .unshelved, to: .shelf("s1"))
            ]
        )

        #expect(plan.hasPendingChanges)
        #expect(plan.hasWork == false)
        #expect(plan.operations.isEmpty)
        #expect(plan.status(of: .shelf("s1")) == .untouched)
        #expect(plan.summary.booksFiled == 0)
        #expect(plan.summary.booksLeftUnshelved == 2)
    }

    /// The same, the long way round: out through a second étagère and home again.
    @Test func aBookThatTravelsAndComesHomeWritesNothing() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .moveBook(bookId: "3", from: .shelf("s2"), to: .shelf("s1")),
                .moveBook(bookId: "3", from: .shelf("s1"), to: .unshelved),
                .moveBook(bookId: "3", from: .unshelved, to: .shelf("s2"))
            ]
        )

        #expect(plan.operations.isEmpty)
        #expect(plan.status(of: .shelf("s1")) == .untouched)
        #expect(plan.status(of: .shelf("s2")) == .untouched)
    }

    // MARK: - What reaches the endpoints

    /// A book moved three times is moved once against the server: one removal where it
    /// started, one addition where it ended, and nothing at all for the étagères it
    /// merely passed through.
    @Test func aBookMovedAcrossThreeSectionsIsOneRemovalAndOneAddition() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
                .moveBook(bookId: "1", from: .shelf("s2"), to: .unshelved),
                .moveBook(bookId: "1", from: .unshelved, to: .shelf("s3"))
            ]
        )

        #expect(plan.operations.count == 2)
        #expect(operation(plan, for: .shelf("s1"))?.removals == ["1"])
        #expect(operation(plan, for: .shelf("s1"))?.additions.isEmpty == true)
        #expect(operation(plan, for: .shelf("s3"))?.additions == ["1"])
        #expect(operation(plan, for: .shelf("s3"))?.removals.isEmpty == true)
        #expect(operation(plan, for: .shelf("s2")) == nil)
        #expect(plan.status(of: .shelf("s2")) == .untouched)
        #expect(plan.summary.booksFiled == 1)
    }

    @Test func aMoveFromOneEtagereToAnotherRemovesOnceAndAddsOnce() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [.moveBook(bookId: "2", from: .shelf("s1"), to: .shelf("s2"))]
        )

        #expect(plan.operations.count == 2)
        #expect(operation(plan, for: .shelf("s1"))?.removals == ["2"])
        #expect(operation(plan, for: .shelf("s1"))?.additions.isEmpty == true)
        #expect(operation(plan, for: .shelf("s2"))?.additions == ["2"])
        #expect(operation(plan, for: .shelf("s2"))?.removals.isEmpty == true)
        #expect(plan.status(of: .shelf("s1")) == .modified)
        #expect(plan.status(of: .shelf("s2")) == .modified)
        #expect(plan.summary.shelvesModified == 2)
        #expect(plan.summary.shelvesToCreate == 0)
    }

    @Test func aBookDroppedIntoThePileIsARemovalAndNothingElse() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [.moveBook(bookId: "3", from: .shelf("s2"), to: .unshelved)]
        )

        #expect(plan.operations.count == 1)
        #expect(operation(plan, for: .shelf("s2"))?.removals == ["3"])
        #expect(operation(plan, for: .shelf("s2"))?.additions.isEmpty == true)
        #expect(operation(plan, for: .shelf("s2"))?.createsShelf == false)
        #expect(plan.summary.booksFiled == 0)
        #expect(plan.summary.booksLeftUnshelved == 3)
    }

    /// Every group takes books off before it puts books on, so a book is never on two
    /// étagères, not even for the duration of a write.
    @Test func anEtagereTakesBooksOffBeforeItPutsBooksOn() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved),
                .moveBook(bookId: "4", from: .unshelved, to: .shelf("s1"))
            ]
        )

        let write: SortWritePlan.ShelfWrite? = operation(plan, for: .shelf("s1"))
        #expect(write?.removals == ["1"])
        #expect(write?.additions == ["4"])
    }

    // MARK: - Étagères that appear, and étagères that empty

    @Test func aDraftHoldingBooksIsOneCreationCarryingItsMembers() {
        let draftId: String = SortDraftID.make()
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .createShelf(draftId: draftId, name: "Science-fiction"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft(draftId)),
                .moveBook(bookId: "5", from: .unshelved, to: .draft(draftId))
            ]
        )

        let write: SortWritePlan.ShelfWrite? = operation(plan, for: .draft(draftId))
        #expect(write?.createsShelf == true)
        #expect(write?.name == "Science-fiction")
        #expect(write?.additions == ["4", "5"])
        #expect(write?.removals.isEmpty == true)
        #expect(plan.status(of: .draft(draftId)) == .new)
        #expect(plan.summary.shelvesToCreate == 1)
        #expect(plan.summary.booksFiled == 2)
        #expect(plan.summary.booksLeftUnshelved == 0)
    }

    /// A new étagère left empty is created all the same, holding nothing. Naming a shelf
    /// is the instruction; filling it is a separate one. The screen listed the creation
    /// among the pending changes and offered to save it, so refusing to create it — which
    /// is what shipped first, following the PRD's user story 35 — read as the screen
    /// ignoring what it had just promised.
    @Test func aDraftLeftEmptyIsCreatedAllTheSame() {
        let draftId: String = SortDraftID.make()
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [.createShelf(draftId: draftId, name: "Science-fiction")]
        )
        let write: SortWritePlan.ShelfWrite? = plan.operations.first

        #expect(plan.operations.count == 1)
        #expect(plan.hasWork)
        #expect(plan.hasPendingChanges)
        #expect(write?.createsShelf == true)
        #expect(write?.name == "Science-fiction")
        #expect(write?.additions.isEmpty == true)
        #expect(write?.removals.isEmpty == true)
        #expect(plan.status(of: .draft(draftId)) == .new)
        #expect(plan.summary.shelvesToCreate == 1)
        #expect(plan.summary.booksFiled == 0)
    }

    /// Filling a draft and then emptying it again leaves the étagère to be created and
    /// the book where it started — the creation is not undone by the book leaving.
    @Test func aDraftFilledAndThenEmptiedIsStillCreated() {
        let draftId: String = SortDraftID.make()
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .createShelf(draftId: draftId, name: "Science-fiction"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft(draftId)),
                .moveBook(bookId: "4", from: .draft(draftId), to: .unshelved)
            ]
        )

        #expect(plan.operations.count == 1)
        #expect(plan.operations.first?.createsShelf == true)
        #expect(plan.operations.first?.additions.isEmpty == true)
        #expect(plan.summary.shelvesToCreate == 1)
        #expect(plan.summary.booksLeftUnshelved == 2)
    }

    /// An étagère emptied by dragging keeps its place and is marked as changed. There
    /// is no deletion to be found anywhere in the plan: a drag never removes a shelf
    /// behind the user's back.
    @Test func anEtagereEmptiedByDraggingIsModifiedAndNeverDeleted() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [.moveBook(bookId: "3", from: .shelf("s2"), to: .shelf("s1"))]
        )

        #expect(plan.status(of: .shelf("s2")) == .modified)
        #expect(operation(plan, for: .shelf("s2"))?.removals == ["3"])
        #expect(operation(plan, for: .shelf("s2"))?.createsShelf == false)

        // The étagère is still one of the sections the screen shows, holding nothing.
        let projection: SortProjection = .init(
            snapshot: library,
            changes: [.moveBook(bookId: "3", from: .shelf("s2"), to: .shelf("s1"))]
        )
        #expect(projection.sections.contains { $0.id == .shelf("s2") && $0.books.isEmpty })
    }

    /// An étagère nothing touches carries no pill and appears in no operation, however
    /// much is going on around it.
    @Test func anUntouchedEtagereIsLeftAlone() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [.moveBook(bookId: "4", from: .unshelved, to: .shelf("s3"))]
        )

        #expect(plan.status(of: .shelf("s1")) == .untouched)
        #expect(plan.status(of: .shelf("s2")) == .untouched)
        #expect(operation(plan, for: .shelf("s1")) == nil)
        #expect(operation(plan, for: .shelf("s2")) == nil)
        #expect(plan.status(of: .shelf("s3")) == .modified)
    }

    // MARK: - Which clauses the sentence is worth saying

    /// A count of zero is not a clause. The session below creates nothing, so the
    /// sentence starts at what did change — « 1 étagère modifiée, … » and never
    /// « 0 étagère à créer, 1 étagère modifiée, … ».
    @Test func aCountOfZeroIsNotSaidAtAll() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [.moveBook(bookId: "4", from: .unshelved, to: .shelf("s1"))]
        )

        #expect(plan.summary.shelvesToCreate == 0)
        #expect(
            plan.summary.clauses == [
                .shelvesModified(1),
                .booksFiled(1),
                .booksLeftUnshelved(1)
            ]
        )
    }

    /// Every number moved, so every clause is said — in the one order they are ever
    /// said in: what gets created, what changes, what that files, what is left over.
    @Test func everyClauseIsSaidInOrderWhenEveryCountMoves() {
        let draftId: String = SortDraftID.make()
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .createShelf(draftId: draftId, name: "Science-fiction"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft(draftId)),
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2"))
            ]
        )

        #expect(
            plan.summary.clauses == [
                .shelvesToCreate(1),
                .shelvesModified(2),
                .booksFiled(2),
                .booksLeftUnshelved(1)
            ]
        )
    }

    /// The case that stops the recap from reading its own clauses to decide what to
    /// say. A stack that coalesces to nothing has no work in it — but the books on no
    /// étagère are still on no étagère, so one clause survives. Rendering it would
    /// answer a question nobody asked; the recap owes « vos changements s'annulent »
    /// here, which is why it gates on `hasWork` and not on the clauses being empty.
    @Test func aStackThatCoalescesToNothingStillLeavesTheUnshelvedClause() {
        let plan: SortWritePlan = .init(
            snapshot: library,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
                .moveBook(bookId: "1", from: .shelf("s2"), to: .shelf("s1"))
            ]
        )

        #expect(plan.hasPendingChanges)
        #expect(plan.hasWork == false)
        #expect(plan.summary.clauses == [.booksLeftUnshelved(2)])
    }

    // MARK: - The pills, the recap and the write, on the same fixtures

    /// The point of the slice: all three readings come out of one reduction, so on any
    /// library and any sequence of gestures they say the same thing. Stated as one
    /// assertion over shared fixtures rather than as three tests that happen to use
    /// similar data — three tests could pass while disagreeing with each other.
    @Test(arguments: SortWritePlanTests.fixtures)
    func thePillsTheRecapAndTheOperationsAlwaysAgree(fixture: Fixture) {
        let snapshot: SortSnapshot = .init(
            shelves: [
                .init(id: "s1", name: "Romans classiques", bookIds: ["1", "2"]),
                .init(id: "s2", name: "Poésie", bookIds: ["3"]),
                .init(id: "s3", name: "Bandes dessinées", bookIds: [])
            ],
            books: [
                .init(id: "1", title: "Livre 1"),
                .init(id: "2", title: "Livre 2"),
                .init(id: "3", title: "Livre 3"),
                .init(id: "4", title: "Livre 4"),
                .init(id: "5", title: "Livre 5")
            ]
        )

        let plan: SortWritePlan = .init(snapshot: snapshot, changes: fixture.changes)
        let projection: SortProjection = .init(snapshot: snapshot, changes: fixture.changes)

        var newPills: Int = 0
        var modifiedPills: Int = 0

        for section in projection.sections {
            let status: SortWritePlan.ShelfStatus = plan.status(of: section.id)
            let write: SortWritePlan.ShelfWrite? = plan.operations.first { $0.section == section.id }

            switch status {
            case .untouched:
                // No pill means nothing to write for that section — including the
                // pile, which is never an operation of its own.
                #expect(write == nil)
            case .new:
                newPills += 1
                // A « Nouvelle » étagère is always created — with its books when it has
                // any, empty when it has none. The pill and the write agree by
                // construction now, which is what the old dropped-draft branch could not
                // promise.
                #expect(write?.createsShelf == true)
                #expect(write?.removals.isEmpty == true)
            case .modified:
                modifiedPills += 1
                #expect(write != nil)
                #expect(write?.createsShelf == false)
                #expect((write?.removals.isEmpty == false) || (write?.additions.isEmpty == false))
            }
        }

        // The recap's numbers are the pills, counted.
        #expect(plan.summary.shelvesToCreate == newPills)
        #expect(plan.summary.shelvesModified == modifiedPills)

        // And the recap's numbers are the operations, counted.
        #expect(plan.summary.shelvesToCreate == plan.operations.count(where: \.createsShelf))
        #expect(plan.summary.booksFiled == plan.operations.reduce(0) { $0 + $1.additions.count })
        #expect(plan.hasWork == (plan.operations.isEmpty == false))

        // And the last number is what the screen actually shows in « À ranger ».
        #expect(plan.summary.booksLeftUnshelved == projection.unshelved.books.count)

        // The sentence says exactly the numbers that moved: as many clauses as there are
        // non-zero counts, so none is dropped and none is padded with a zero.
        let counts: [Int] = [
            plan.summary.shelvesToCreate,
            plan.summary.shelvesModified,
            plan.summary.booksFiled,
            plan.summary.booksLeftUnshelved
        ]
        #expect(plan.summary.clauses.count == counts.count { $0 > 0 })
    }

    /// One sorting session, as a value the agreement test can be handed. Named so a
    /// failure says which session broke rather than printing a stack of changes.
    struct Fixture: CustomTestStringConvertible, Sendable {
        let name: String
        let changes: [SortChange]

        var testDescription: String { name }
    }

    private static let draftId: String = SortDraftID.make()
    private static let otherDraftId: String = SortDraftID.make()

    static let fixtures: [Fixture] = [
        .init(name: "nothing done", changes: []),
        .init(
            name: "one book filed",
            changes: [.moveBook(bookId: "4", from: .unshelved, to: .shelf("s1"))]
        ),
        .init(
            name: "one book unfiled",
            changes: [.moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved)]
        ),
        .init(
            name: "an étagère emptied",
            changes: [.moveBook(bookId: "3", from: .shelf("s2"), to: .unshelved)]
        ),
        .init(
            name: "out and back",
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
                .moveBook(bookId: "1", from: .shelf("s2"), to: .shelf("s1"))
            ]
        ),
        .init(
            name: "a book across three sections",
            changes: [
                .moveBook(bookId: "2", from: .shelf("s1"), to: .shelf("s2")),
                .moveBook(bookId: "2", from: .shelf("s2"), to: .unshelved),
                .moveBook(bookId: "2", from: .unshelved, to: .shelf("s3"))
            ]
        ),
        .init(
            name: "a draft filled",
            changes: [
                .createShelf(draftId: draftId, name: "Science-fiction"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft(draftId)),
                .moveBook(bookId: "5", from: .unshelved, to: .draft(draftId))
            ]
        ),
        .init(
            name: "a draft left empty",
            changes: [.createShelf(draftId: draftId, name: "Science-fiction")]
        ),
        .init(
            name: "one draft filled, one left empty",
            changes: [
                .createShelf(draftId: draftId, name: "Science-fiction"),
                .createShelf(draftId: otherDraftId, name: "Essais"),
                .moveBook(bookId: "4", from: .unshelved, to: .draft(draftId))
            ]
        ),
        .init(
            name: "a whole afternoon of sorting",
            changes: [
                .createShelf(draftId: draftId, name: "Science-fiction"),
                .moveBook(bookId: "1", from: .shelf("s1"), to: .draft(draftId)),
                .moveBook(bookId: "2", from: .shelf("s1"), to: .unshelved),
                .moveBook(bookId: "3", from: .shelf("s2"), to: .shelf("s3")),
                .moveBook(bookId: "4", from: .unshelved, to: .shelf("s2")),
                .moveBook(bookId: "5", from: .unshelved, to: .draft(draftId)),
                .moveBook(bookId: "5", from: .draft(draftId), to: .unshelved),
                .createShelf(draftId: otherDraftId, name: "Essais")
            ]
        )
    ]
}
