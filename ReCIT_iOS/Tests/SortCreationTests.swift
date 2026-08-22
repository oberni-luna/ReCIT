//
//  SortCreationTests.swift
//  ReCIT_iOSTests
//
//  Creating an étagère by dropping a book onto the grid's « + » tile: one gesture, two changes,
//  and the ways it could betray the user. A move naming a draft nobody created is silently
//  ignored by the projection, so the book would sit where it always was while the screen said
//  otherwise — which is why the pair is one rule and not two calls. See PRD 0009.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortChange.creation")
struct SortCreationTests {

    @Test func namingAnEtagereWithoutABookIsOneChange() {
        let changes: [SortChange] = SortChange.creation(draftId: "draft:1", name: "Poésie")

        #expect(changes == [.createShelf(draftId: "draft:1", name: "Poésie")])
    }

    @Test func droppingABookOntoTheTileCreatesAndFiles() {
        let changes: [SortChange] = SortChange.creation(
            draftId: "draft:1",
            name: "Poésie",
            filling: "book-1",
            from: .unshelved
        )

        #expect(changes == [
            .createShelf(draftId: "draft:1", name: "Poésie"),
            .moveBook(bookId: "book-1", from: .unshelved, to: .draft("draft:1"))
        ])
    }

    /// The creation comes first, so the projection knows the section by the time the move
    /// names it. Reversed, the move would be dropped and the book would stay put.
    @Test func theCreationPrecedesTheMove() {
        let changes: [SortChange] = SortChange.creation(
            draftId: "draft:1",
            name: "Poésie",
            filling: "book-1",
            from: .shelf("s1")
        )

        guard case .createShelf = changes.first else {
            Issue.record("the creation must come first, got \(String(describing: changes.first))")
            return
        }
    }

    /// A book the projection does not know cannot be filed — but the étagère is still created,
    /// because naming one is an instruction of its own.
    @Test func anUnknownBookStillLeavesTheEtagereCreated() {
        let changes: [SortChange] = SortChange.creation(
            draftId: "draft:1",
            name: "Poésie",
            filling: "book-1",
            from: nil
        )

        #expect(changes == [.createShelf(draftId: "draft:1", name: "Poésie")])
    }

    /// Dropping a book onto the tile from the very draft being created cannot happen through
    /// the screen, and records no move if it ever does: a move to where the book already is is
    /// nothing at all.
    @Test func aBookAlreadyInTheDraftRecordsNoMove() {
        let changes: [SortChange] = SortChange.creation(
            draftId: "draft:1",
            name: "Poésie",
            filling: "book-1",
            from: .draft("draft:1")
        )

        #expect(changes.count == 1)
    }
}
