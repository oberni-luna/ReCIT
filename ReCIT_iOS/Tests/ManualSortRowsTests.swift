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

    /// Two étagères and the pile: `[header s1, b1, b2, header s2, b3, header pile, b4]`.
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

    @Test func onlyBooksCanBeDragged() {
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

    /// An emptied étagère still offers a row, so a book dragged off it can be put back.
    /// Without one it would be a drop target zero points tall.
    @Test func anEmptyEtagereStillOffersARowToLandOn() {
        let rows: ManualSortRows = .init(
            sections: [
                .init(id: .shelf("s1"), name: "Romans", books: []),
                .init(id: .unshelved, name: nil, books: [.init(id: "1", title: "A")])
            ]
        )

        #expect(rows.rows.count == 4)
        #expect(rows.rows[1].isMovable == false)
        #expect(rows.section(forInsertionAt: 2) == .shelf("s1"))
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
