//
//  SortProjectionTests.swift
//  ReCIT_iOSTests
//
//  The one rule the sorting surface cannot get wrong: **every book sits in exactly one
//  section**. A book shown twice would be written twice by the apply, and a book shown
//  nowhere would silently vanish from a user's library on a screen whose whole promise
//  is that nothing is lost.
//
//  Pure and store-free: the projection takes two value types and returns a third,
//  which is exactly why PRD 0008 freezes the snapshot in the first place.
//
//  Each test states what the *screen shows* given a snapshot and a stack — never how
//  the reduction gets there. See PRD 0008.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortProjection")
struct SortProjectionTests {

    private func book(_ id: String) -> AutoSortBook {
        .init(id: id, title: "Livre \(id)")
    }

    private func shelf(_ id: String, _ name: String, _ bookIds: [String]) -> SortSnapshot.Shelf {
        .init(id: id, name: name, bookIds: bookIds)
    }

    /// The invariant, asked of a whole projection rather than of one section: every
    /// book of the snapshot appears once, and nothing appears that was not in it.
    private func expectEveryBookAppearsExactlyOnce(
        _ projection: SortProjection,
        in snapshot: SortSnapshot,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let shown: [String] = projection.sections.flatMap { $0.books.map(\.id) }
        let expected: Set<String> = .init(snapshot.books.map(\.id))

        #expect(shown.count == expected.count, sourceLocation: sourceLocation)
        #expect(Set(shown) == expected, sourceLocation: sourceLocation)
    }

    // MARK: - The library, laid out as it is filed

    @Test func eachEtagereShowsTheBooksItHoldsAndTheRestFallIntoThePile() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1", "2"]),
                shelf("s2", "Poésie", ["3"])
            ],
            books: [book("1"), book("2"), book("3"), book("4")]
        )

        let projection: SortProjection = .init(snapshot: snapshot)

        #expect(projection.sections.map(\.name) == ["Romans classiques", "Poésie", nil])
        #expect(projection.sections[0].books.map(\.id) == ["1", "2"])
        #expect(projection.sections[1].books.map(\.id) == ["3"])
        #expect(projection.unshelved.books.map(\.id) == ["4"])
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    @Test func thePileComesLast() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Poésie", ["1"])],
            books: [book("1"), book("2")]
        )

        let projection: SortProjection = .init(snapshot: snapshot)

        #expect(projection.sections.last?.isUnshelved == true)
        #expect(projection.sections.dropLast().allSatisfy { $0.isUnshelved == false })
    }

    @Test func aSectionsCountIsTheNumberOfRowsUnderIt() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Romans classiques", ["1", "2", "3"])],
            books: [book("1"), book("2"), book("3")]
        )

        let projection: SortProjection = .init(snapshot: snapshot)

        for section in projection.sections {
            #expect(section.bookCount == section.books.count)
        }
        #expect(projection.sections[0].bookCount == 3)
    }

    // MARK: - Every book in exactly one section, whatever the store holds

    /// The store's `Shelf ⇄ InventoryItem` relation is many-to-many, so a copy really
    /// can be on two étagères (ADR 0003). On this screen it is filed under the first
    /// one — the same partition rule the auto-sort plan keeps for a multi-genre book,
    /// and for the same reason: showing it twice would write it twice.
    @Test func aBookOnTwoEtageresIsShownUnderTheFirstOnly() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1"]),
                shelf("s2", "Poésie", ["1"])
            ],
            books: [book("1")]
        )

        let projection: SortProjection = .init(snapshot: snapshot)

        #expect(projection.sections[0].books.map(\.id) == ["1"])
        #expect(projection.sections[1].books.isEmpty)
        #expect(projection.unshelved.books.isEmpty)
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    @Test func anEtagereWithNoBooksStaysOnScreenEmpty() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Romans classiques", [])],
            books: [book("1")]
        )

        let projection: SortProjection = .init(snapshot: snapshot)

        #expect(projection.sections.count == 2)
        #expect(projection.sections[0].name == "Romans classiques")
        #expect(projection.sections[0].books.isEmpty)
        #expect(projection.unshelved.books.map(\.id) == ["1"])
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    @Test func anEmptyLibraryShowsThePileAndNothingElse() {
        let snapshot: SortSnapshot = .empty

        let projection: SortProjection = .init(snapshot: snapshot)

        #expect(projection.sections.count == 1)
        #expect(projection.sections[0].isUnshelved)
        #expect(projection.sections[0].books.isEmpty)
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    /// An étagère listing an item the inventory no longer holds must not conjure a row
    /// for it: the count in the header would then exceed the rows under it.
    @Test func anEtagereListingABookTheInventoryNoLongerHoldsShowsNothingForIt() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Romans classiques", ["1", "ghost"])],
            books: [book("1")]
        )

        let projection: SortProjection = .init(snapshot: snapshot)

        #expect(projection.sections[0].books.map(\.id) == ["1"])
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    // MARK: - Whatever the stack

    @Test func anEmptyStackShowsTheLibraryExactlyAsItIsFiled() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Romans classiques", ["1"])],
            books: [book("1"), book("2")]
        )

        #expect(SortProjection(snapshot: snapshot, changes: []) == SortProjection(snapshot: snapshot))
    }

    @Test func aBookMovedOntoAnEtagereLeavesThePileForIt() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Romans classiques", [])],
            books: [book("1")]
        )

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [.moveBook(bookId: "1", from: .unshelved, to: .shelf("s1"))]
        )

        #expect(projection.sections[0].books.map(\.id) == ["1"])
        #expect(projection.unshelved.books.isEmpty)
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    @Test func aBookMovedTwiceEndsUpInOnePlaceOnly() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1"]),
                shelf("s2", "Poésie", [])
            ],
            books: [book("1")]
        )

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved),
                .moveBook(bookId: "1", from: .unshelved, to: .shelf("s2"))
            ]
        )

        #expect(projection.sections[0].books.isEmpty)
        #expect(projection.sections[1].books.map(\.id) == ["1"])
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    @Test func aDraftEtagereShowsTheBooksMovedIntoIt() {
        let draftId: String = SortDraftID.make()
        let snapshot: SortSnapshot = .init(books: [book("1"), book("2")])

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [
                .createShelf(draftId: draftId, name: "Bandes dessinées"),
                .moveBook(bookId: "2", from: .unshelved, to: .draft(draftId))
            ]
        )

        #expect(projection.sections.map(\.name) == ["Bandes dessinées", nil])
        #expect(projection.sections[0].books.map(\.id) == ["2"])
        #expect(projection.unshelved.books.map(\.id) == ["1"])
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    /// A stack that names a section or a book the snapshot does not know must not be
    /// able to lose a book. The apply rebuilds the snapshot as it goes (PRD 0008), so
    /// a stale change is a real state, not a hypothetical one.
    @Test func aChangeNamingSomethingUnknownLosesNoBook() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Romans classiques", ["1"])],
            books: [book("1"), book("2")]
        )

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [
                .moveBook(bookId: "2", from: .unshelved, to: .shelf("gone")),
                .moveBook(bookId: "ghost", from: .unshelved, to: .shelf("s1"))
            ]
        )

        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
        #expect(projection.unshelved.books.map(\.id) == ["2"])
    }

    // MARK: - Dragging a book from one section to another

    @Test func aBookDraggedFromOneEtagereToAnotherLeavesOneAndJoinsTheOther() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1", "2"]),
                shelf("s2", "Poésie", ["3"])
            ],
            books: [book("1"), book("2"), book("3")]
        )

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [.moveBook(bookId: "2", from: .shelf("s1"), to: .shelf("s2"))]
        )

        #expect(projection.sections[0].books.map(\.id) == ["1"])
        // Snapshot order, because no display order was handed in. Order within an étagère
        // is not part of what gets written; the screen passes the permutation its own list
        // performed, and everything else reads the library as the server holds it.
        #expect(projection.sections[1].books.map(\.id) == ["2", "3"])
        #expect(projection.unshelved.books.isEmpty)
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    @Test func aBookDroppedIntoThePileLeavesItsEtagere() {
        let snapshot: SortSnapshot = .init(
            shelves: [shelf("s1", "Romans classiques", ["1", "2"])],
            books: [book("1"), book("2")]
        )

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [.moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved)]
        )

        #expect(projection.sections[0].books.map(\.id) == ["2"])
        #expect(projection.unshelved.books.map(\.id) == ["1"])
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    @Test func aBookDraggedAcrossThreeSectionsEndsUpInExactlyOne() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1"]),
                shelf("s2", "Poésie", []),
                shelf("s3", "Bandes dessinées", [])
            ],
            books: [book("1")]
        )

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
                .moveBook(bookId: "1", from: .shelf("s2"), to: .unshelved),
                .moveBook(bookId: "1", from: .unshelved, to: .shelf("s3"))
            ]
        )

        #expect(projection.sections[0].books.isEmpty)
        #expect(projection.sections[1].books.isEmpty)
        #expect(projection.sections[2].books.map(\.id) == ["1"])
        #expect(projection.unshelved.books.isEmpty)
        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
    }

    /// A book put back where it came from records nothing, so the screen does not end
    /// up claiming there is work to discard.
    @Test func aBookDroppedBackOnTheSectionItCameFromRecordsNothing() {
        #expect(SortChange.move(bookId: "1", from: .shelf("s1"), to: .shelf("s1")) == nil)
        #expect(SortChange.move(bookId: "1", from: .unshelved, to: .unshelved) == nil)
        #expect(
            SortChange.move(bookId: "1", from: .unshelved, to: .shelf("s1"))
                == .moveBook(bookId: "1", from: .unshelved, to: .shelf("s1"))
        )
    }

    // MARK: - The counts, and what discarding restores

    @Test func theCountInAHeaderFollowsTheMoves() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1", "2"]),
                shelf("s2", "Poésie", [])
            ],
            books: [book("1"), book("2"), book("3")]
        )

        #expect(SortProjection(snapshot: snapshot).sections.map(\.bookCount) == [2, 0, 1])

        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [
                .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
                .moveBook(bookId: "3", from: .unshelved, to: .shelf("s2"))
            ]
        )

        #expect(projection.sections.map(\.bookCount) == [1, 2, 0])
    }

    /// « Annuler » throws the stack away, and the screen has to come back to the
    /// library it opened on — not to something close to it.
    @Test func discardingTheStackRestoresTheSnapshotExactly() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1", "2"]),
                shelf("s2", "Poésie", ["3"])
            ],
            books: [book("1"), book("2"), book("3"), book("4")]
        )
        let changes: [SortChange] = [
            .createShelf(draftId: SortDraftID.make(), name: "Bandes dessinées"),
            .moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2")),
            .moveBook(bookId: "4", from: .unshelved, to: .shelf("s1"))
        ]

        let sorted: SortProjection = .init(snapshot: snapshot, changes: changes)
        #expect(sorted != SortProjection(snapshot: snapshot))

        #expect(SortProjection(snapshot: snapshot, changes: []) == SortProjection(snapshot: snapshot))
    }

    // MARK: - The invariant, over every stack dragging can build

    /// Whatever sequence of drops the user makes, and in whatever order, the screen
    /// shows each of their books once. Stated over the stacks this gesture makes
    /// reachable rather than over one of them, because the rule is about the reduction
    /// and not about a case.
    @Test(
        arguments: [
            [],
            [SortChange.moveBook(bookId: "1", from: .shelf("s1"), to: .shelf("s2"))],
            [
                SortChange.moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved),
                SortChange.moveBook(bookId: "3", from: .unshelved, to: .shelf("s1"))
            ],
            [
                SortChange.moveBook(bookId: "2", from: .shelf("s1"), to: .shelf("s2")),
                SortChange.moveBook(bookId: "2", from: .shelf("s2"), to: .unshelved),
                SortChange.moveBook(bookId: "2", from: .unshelved, to: .shelf("s1"))
            ],
            [
                SortChange.moveBook(bookId: "1", from: .shelf("s1"), to: .unshelved),
                SortChange.moveBook(bookId: "2", from: .shelf("s1"), to: .unshelved),
                SortChange.moveBook(bookId: "3", from: .unshelved, to: .shelf("s2"))
            ]
        ]
    )
    func everyBookSitsInExactlyOneSectionWhateverTheStack(changes: [SortChange]) {
        let snapshot: SortSnapshot = .init(
            shelves: [
                shelf("s1", "Romans classiques", ["1", "2"]),
                shelf("s2", "Poésie", [])
            ],
            books: [book("1"), book("2"), book("3")]
        )

        let projection: SortProjection = .init(snapshot: snapshot, changes: changes)

        expectEveryBookAppearsExactlyOnce(projection, in: snapshot)
        #expect(projection.sections.map(\.bookCount).reduce(0, +) == snapshot.books.count)
    }

    @Test func aDraftIdIsNeverMistakenForAServerDocument() {
        #expect(SortDraftID.isDraft(SortDraftID.make()))
        #expect(SortDraftID.isDraft("d3fbdd9e0a8d2b1c") == false)
    }
    /// A display order puts a book exactly where it was dropped — including *between* two
    /// books already on the shelf, which is the drop the list animates and which no order
    /// derived from the snapshot could reproduce.
    @Test func aDisplayOrderPlacesABookExactlyWhereItWasDropped() {
        let snapshot: SortSnapshot = .init(
            shelves: [.init(id: "s1", name: "Romans", bookIds: ["1", "2"])],
            books: [
                .init(id: "1", title: "A"),
                .init(id: "2", title: "B"),
                .init(id: "3", title: "C")
            ]
        )
        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [.moveBook(bookId: "3", from: .unshelved, to: .shelf("s1"))],
            displayOrder: ["1", "3", "2"]
        )

        #expect(projection.sections.first?.books.map(\.id) == ["1", "3", "2"])
    }

    /// A book the display order does not mention keeps its snapshot position, after the
    /// ones it does — so a partial order is still a total one and no book is lost.
    @Test func aBookTheDisplayOrderDoesNotMentionKeepsItsPlace() {
        let snapshot: SortSnapshot = .init(
            shelves: [.init(id: "s1", name: "Romans", bookIds: ["1", "2", "3"])],
            books: [
                .init(id: "1", title: "A"),
                .init(id: "2", title: "B"),
                .init(id: "3", title: "C")
            ]
        )
        let projection: SortProjection = .init(
            snapshot: snapshot,
            displayOrder: ["3"]
        )

        #expect(projection.sections.first?.books.map(\.id) == ["3", "1", "2"])
    }

    /// The display order never moves a book between sections — that is the stack's job, and
    /// mixing the two is how a screen and a write start disagreeing.
    @Test func aDisplayOrderNeverRefilesABook() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                .init(id: "s1", name: "Romans", bookIds: ["1"]),
                .init(id: "s2", name: "Poésie", bookIds: ["2"])
            ],
            books: [.init(id: "1", title: "A"), .init(id: "2", title: "B")]
        )
        let projection: SortProjection = .init(
            snapshot: snapshot,
            displayOrder: ["2", "1"]
        )

        #expect(projection.sections[0].books.map(\.id) == ["1"])
        #expect(projection.sections[1].books.map(\.id) == ["2"])
    }

    @Test func aBookMovedOntoAnEtagereJoinsIt() {
        let snapshot: SortSnapshot = .init(
            shelves: [.init(id: "s1", name: "Romans", bookIds: ["1", "2"])],
            books: [
                .init(id: "1", title: "A"),
                .init(id: "2", title: "B"),
                .init(id: "3", title: "C")
            ]
        )
        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [.moveBook(bookId: "3", from: .unshelved, to: .shelf("s1"))]
        )

        #expect(projection.sections.first?.books.map(\.id) == ["1", "2", "3"])
    }

    /// A book nobody has touched keeps its snapshot position, so an untouched étagère is
    /// not reshuffled by a move that happened elsewhere.
    @Test func anUntouchedEtagereKeepsItsOrder() {
        let snapshot: SortSnapshot = .init(
            shelves: [
                .init(id: "s1", name: "Romans", bookIds: ["1", "2", "3"]),
                .init(id: "s2", name: "Poésie", bookIds: ["4"])
            ],
            books: (1...4).map { .init(id: "\($0)", title: "T\($0)") }
        )
        let projection: SortProjection = .init(
            snapshot: snapshot,
            changes: [.moveBook(bookId: "4", from: .shelf("s2"), to: .unshelved)]
        )

        #expect(projection.sections.first?.books.map(\.id) == ["1", "2", "3"])
    }

}
