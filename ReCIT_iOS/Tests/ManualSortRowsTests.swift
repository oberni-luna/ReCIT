//
//  ManualSortRowsTests.swift
//  ReCIT_iOSTests
//
//  The rule that decides which étagère a book has been dropped into, asserted as
//  sentences rather than exercised through a gesture.
//
//  This is the whole reason the flattening is a value type: `onMove` hands over an index
//  into a list, and "which étagère is that" is the one piece of arithmetic that can file a
//  book on the wrong shelf. It is worth being able to state it without a simulator.
//

import Testing
@testable import ReCIT_iOS

@Suite("Manual sort rows")
struct ManualSortRowsTests {

    /// Two étagères and the pile: `[h s1, b1, b2, h s2, b3, h pile, b4]`. No section is
    /// empty here, so no header is a drop target.
    private let sections: [SortSection] = [
        .init(id: .shelf("s1"), name: "Romans", books: [.init(id: "1", title: "A"), .init(id: "2", title: "B")]),
        .init(id: .shelf("s2"), name: "Poésie", books: [.init(id: "3", title: "C")]),
        .init(id: .unshelved, name: nil, books: [.init(id: "4", title: "D")])
    ]

    @Test func everyEtagereContributesAHeaderAndItsBooks() {
        let rows: ManualSortRows = .init(sections: sections)

        #expect(rows.rows.count == 7)
        #expect(rows.rows.map(\.section) == [
            .shelf("s1"), .shelf("s1"), .shelf("s1"),
            .shelf("s2"), .shelf("s2"),
            .unshelved, .unshelved
        ])
    }

    @Test func headersDoNotMoveAndEverythingElseDoes() {
        let rows: ManualSortRows = .init(sections: sections)
        let movable: [Bool] = rows.rows.map(\.isMovable)

        #expect(movable == [false, true, true, false, true, false, true])
    }

    /// The card's corners: the first and last book of each étagère carry them, the ones
    /// in between carry neither, and a lone book carries both.
    @Test func theCardIsRoundedAtTheEndsOfEachEtagere() {
        let rows: ManualSortRows = .init(sections: sections)
        let corners: [(Bool, Bool)] = rows.rows.map { ($0.isCardTop, $0.isCardBottom) }

        #expect(corners.map(\.0) == [false, true, false, false, true, false, true])
        #expect(corners.map(\.1) == [false, false, true, false, true, false, true])
    }

    /// Dropping just under an étagère's header lands in that étagère.
    @Test func aBookDroppedUnderAHeaderLandsInThatEtagere() {
        let rows: ManualSortRows = .init(sections: sections)

        #expect(rows.section(forInsertionAt: 1) == .shelf("s1"))
        #expect(rows.section(forInsertionAt: 4) == .shelf("s2"))
        #expect(rows.section(forInsertionAt: 6) == .unshelved)
    }

    /// Dropping *onto* a header lands in the étagère above it — the finger is at the
    /// boundary, and the row above is the one it left the gap under.
    @Test func aBookDroppedOnAHeaderLandsInTheEtagereAbove() {
        let rows: ManualSortRows = .init(sections: sections)

        #expect(rows.section(forInsertionAt: 3) == .shelf("s1"))
        #expect(rows.section(forInsertionAt: 5) == .shelf("s2"))
    }

    /// Above the very first header there is nothing to be above, so the first étagère
    /// takes it rather than the drop being refused.
    @Test func aBookDroppedAtTheVeryTopLandsInTheFirstEtagere() {
        let rows: ManualSortRows = .init(sections: sections)

        #expect(rows.section(forInsertionAt: 0) == .shelf("s1"))
    }

    /// And at the very bottom, in the pile — which is what makes unfiling a book the
    /// same gesture as filing one.
    @Test func aBookDroppedAtTheVeryBottomLandsInThePile() {
        let rows: ManualSortRows = .init(sections: sections)

        #expect(rows.section(forInsertionAt: rows.rows.count) == .unshelved)
        #expect(rows.section(forInsertionAt: 99) == .unshelved)
    }

    /// **An empty étagère contributes only its header, and that header is the drop target.**
    /// It used to get a placeholder row of its own; filling it then deleted a row while the
    /// list had just performed a length-preserving move, so SwiftUI animated an insertion
    /// and a deletion on top of the drop and the two rows overlapped for a third of a
    /// second. With no placeholder, a move only ever changes which section a book belongs
    /// to — never how many rows there are.
    @Test func anEmptyEtagereIsJustItsHeaderAndThatHeaderMoves() {
        let rows: ManualSortRows = .init(
            sections: [
                .init(id: .shelf("s1"), name: "Romans", books: []),
                .init(id: .unshelved, name: nil, books: [.init(id: "1", title: "A")])
            ]
        )

        #expect(rows.rows.count == 3)
        #expect(rows.rows.map(\.isMovable) == [true, false, true])
        #expect(rows.rows[0].isEmptySectionHeader)
        #expect(rows.rows[1].isEmptySectionHeader == false)
    }

    /// Filling an étagère leaves the row count and every identity untouched — which is the
    /// whole point of dropping the placeholder.
    @Test func fillingAnEtagereChangesNoRowCountAndNoIdentity() {
        let before: ManualSortRows = .init(
            sections: [
                .init(id: .shelf("s1"), name: "Romans", books: []),
                .init(id: .unshelved, name: nil, books: [.init(id: "1", title: "A")])
            ]
        )
        let after: ManualSortRows = .init(
            sections: [
                .init(id: .shelf("s1"), name: "Romans", books: [.init(id: "1", title: "A")]),
                .init(id: .unshelved, name: nil, books: [])
            ]
        )

        #expect(before.rows.count == after.rows.count)
        #expect(Set(before.rows.map(\.id)) == Set(after.rows.map(\.id)))
    }

    /// The boundary just before an empty étagère belongs to *it*, not to the étagère above.
    /// Its header is the only row it has, so that gap is the only place a finger can aim to
    /// fill it — while the étagère above stays reachable by dropping onto any of its books.
    @Test func theGapBeforeAnEmptyEtagereFillsTheEmptyOne() {
        let rows: ManualSortRows = .init(
            sections: [
                .init(id: .shelf("s1"), name: "Romans", books: [.init(id: "1", title: "A"), .init(id: "2", title: "B")]),
                .init(id: .shelf("s2"), name: "Poésie", books: []),
                .init(id: .unshelved, name: nil, books: [.init(id: "3", title: "C")])
            ]
        )

        // [0 h s1, 1 b1, 2 b2, 3 h s2 (empty), 4 h pile, 5 b3]
        #expect(rows.section(forInsertionAt: 3) == .shelf("s2"))
        // And the shelf above is still reachable, by aiming at one of its own books.
        #expect(rows.section(forInsertionAt: 2) == .shelf("s1"))
        // Past the empty one, the boundary reads normally again.
        #expect(rows.section(forInsertionAt: 4) == .shelf("s2"))
        #expect(rows.section(forInsertionAt: 5) == .unshelved)
    }

    /// The pile once every book is filed — the same case, at the end of the list.
    @Test func anEmptyPileStillAcceptsABookBack() {
        let rows: ManualSortRows = .init(
            sections: [
                .init(id: .shelf("s1"), name: "Romans", books: [.init(id: "1", title: "A")]),
                .init(id: .unshelved, name: nil, books: [])
            ]
        )

        #expect(rows.rows.map(\.isMovable) == [false, true, true])
        #expect(rows.section(forInsertionAt: 2) == .unshelved)
        #expect(rows.section(forInsertionAt: 3) == .unshelved)
    }

    /// Picking up an empty étagère's header pushes nothing — it is a target, not a book.
    @Test func anEmptyHeaderPickedUpMovesNoBook() {
        let rows: ManualSortRows = .init(
            sections: [
                .init(id: .shelf("s1"), name: "Romans", books: []),
                .init(id: .unshelved, name: nil, books: [])
            ]
        )

        #expect(rows.rows.count == 2)
        #expect(rows.book(at: 0) == nil)
        #expect(rows.book(at: 1) == nil)
    }

    /// The two halves a move records: which book, and which étagère it is leaving.
    @Test func theBookPickedUpCarriesTheEtagereItIsLeaving() {
        let rows: ManualSortRows = .init(sections: sections)

        #expect(rows.book(at: 2)?.id == "2")
        #expect(rows.book(at: 2)?.origin == .shelf("s1"))
        #expect(rows.book(at: 6)?.origin == .unshelved)
    }

    /// A header is not a book, and neither is an index off the end.
    @Test func nothingIsPickedUpFromAHeaderOrPastTheEnd() {
        let rows: ManualSortRows = .init(sections: sections)

        #expect(rows.book(at: 0) == nil)
        #expect(rows.book(at: 99) == nil)
    }

    @Test func anEmptyLibraryHasNowhereToDrop() {
        let rows: ManualSortRows = .init(sections: [])

        #expect(rows.rows.isEmpty)
        #expect(rows.section(forInsertionAt: 0) == nil)
    }
}
