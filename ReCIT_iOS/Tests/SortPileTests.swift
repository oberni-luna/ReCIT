//
//  SortPileTests.swift
//  ReCIT_iOSTests
//
//  What an étagère's card draws, and — the assertion this suite exists for — **which book
//  a drag from that card carries**. The card's drag source is one cover, so if position and
//  rank ever disagree the user grabs a book they are not looking at, silently. See PRD 0009.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortPile")
struct SortPileTests {

    private func book(_ id: String, _ title: String) -> AutoSortBook {
        .init(id: id, title: title)
    }

    private func books(_ count: Int) -> [AutoSortBook] {
        (1...count).map { book("\($0)", "Livre \($0)") }
    }

    // MARK: - What is drawn

    @Test func aPileDrawsAtMostFiveCovers() {
        let pile: SortPile = .init(books: books(12))

        #expect(pile.covers.count == 5)
        #expect(pile.bookCount == 12)
    }

    @Test func aPileDrawsEveryCoverOfASmallShelf() {
        let pile: SortPile = .init(books: books(3))

        #expect(pile.covers.map(\.book.id) == ["1", "2", "3"])
        #expect(pile.bookCount == 3)
    }

    @Test func oneBookIsACoverRatherThanAPile() {
        let pile: SortPile = .init(books: books(1))

        #expect(pile.isSingleCover)
        #expect(pile.isEmpty == false)
    }

    /// The normal state of a draft, for as long as it takes to drop the first book on it —
    /// so it must be a well-formed pile of nothing, not a special case.
    @Test func anEmptyEtagereDrawsNoCoverAndHandsOverNoBook() {
        let pile: SortPile = .init(books: [])

        #expect(pile.isEmpty)
        #expect(pile.covers.isEmpty)
        #expect(pile.draggableBook == nil)
        #expect(pile.bookCount == 0)
    }

    // MARK: - The book a drag carries

    /// The whole point of the type: front cover, first book of the section, one and the
    /// same. `SortProjection` puts the most recently filed book first, so this is also
    /// "the book you just dropped is the book you can take back".
    @Test func theDraggableBookIsTheFrontOfThePile() {
        let pile: SortPile = .init(books: books(5))

        #expect(pile.draggableBook?.id == "1")
        #expect(pile.covers.first?.book.id == "1")
        #expect(pile.covers.first?.depth == 0)
    }

    @Test func depthGrowsTowardsTheBackOfThePile() {
        let pile: SortPile = .init(books: books(4))

        #expect(pile.covers.map(\.depth) == [0, 1, 2, 3])
    }

    /// The section is the only source of order — the pile never re-sorts. A pile that
    /// sorted by title would hand over a different book from the one the projection says
    /// is on top.
    @Test func aPileKeepsTheOrderTheSectionGaveIt() {
        let section: SortSection = .init(
            id: .shelf("s1"),
            name: "Romans",
            books: [book("9", "Zoé"), book("4", "Alpha"), book("7", "Milieu")]
        )
        let pile: SortPile = .init(section: section)

        #expect(pile.covers.map(\.book.id) == ["9", "4", "7"])
        #expect(pile.draggableBook?.id == "9")
    }

    // MARK: - Lean

    @Test func everyCoverLeansWithinTenDegrees() {
        let pile: SortPile = .init(books: [
            book("1", "Classiques français"),
            book("2", "Théâtre"),
            book("3", "Éditions rares"),
            book("4", "Science-fiction"),
            book("5", "")
        ])

        for cover in pile.covers {
            #expect(cover.tiltDegrees >= -SortPile.tiltAmplitude)
            #expect(cover.tiltDegrees <= SortPile.tiltAmplitude)
        }
    }

    /// Same shelf, same lean, every launch. A process-seeded hash would pass any single
    /// run of this test and re-roll the pile on every cold start.
    @Test func aPileLeansTheSameWayEveryTime() {
        let first: SortPile = .init(books: books(5))
        let second: SortPile = .init(books: books(5))

        #expect(first.covers.map(\.tiltDegrees) == second.covers.map(\.tiltDegrees))
    }

    /// Two French titles of similar shape must not share an angle: that is what makes a
    /// pile read as handled rather than as stamped.
    @Test func similarTitlesDoNotShareOneAngle() {
        let pile: SortPile = .init(books: [
            book("1", "Le ministère des rêves"),
            book("2", "Le ministère des rires"),
            book("3", "Le ministère des rives")
        ])

        #expect(Set(pile.covers.map(\.tiltDegrees)).count == 3)
    }
}
