//
//  AutoSortPlanTests.swift
//  ReCIT_iOSTests
//
//  Phase 3 — the step issue 0024 will turn into writes. Pure and network-free: no
//  model, no store, no SwiftUI.
//
//  It is arithmetic, and that is the point: because it is code rather than a
//  prompt, the assignment that will eventually mutate the user's library cannot
//  invent an étagère. What is pinned here is that it also never *defaults* one —
//  a book whose genre the mapping does not cover is left where it is rather than
//  swept into the nearest shelf, and a shelf that ends up with nothing on it is
//  dropped rather than proposed empty. See PRD 0006.
//

import Testing
@testable import ReCIT_iOS

@Suite("AutoSortPlan")
struct AutoSortPlanTests {

    private let taxonomy: [String] = [
        "Littérature de l'imaginaire",
        "Romans policiers",
        "Essais et documents"
    ]

    private func book(_ id: String, genres: [String] = []) -> AutoSortBook {
        .init(id: id, title: "Livre \(id)", genres: genres)
    }

    /// Built through the validator rather than by hand, so the plan is only ever
    /// tested against a mapping it could actually be given.
    private func mapping(
        _ pairs: [(String, String)],
        taxonomy: [String]? = nil
    ) throws -> ValidatedGenreMapping {
        try ShelfMappingValidator.validate(
            taxonomy: taxonomy ?? self.taxonomy,
            assignments: pairs.map { .init(genre: $0.0, shelfName: $0.1) },
            offeredGenres: pairs.map(\.0)
        )
    }

    // MARK: - Books land where their genre says

    @Test func eachBookLandsOnTheShelfItsGenreMapsTo() throws {
        let mapping: ValidatedGenreMapping = try mapping([
            ("science-fiction", "Littérature de l'imaginaire"),
            ("roman policier", "Romans policiers")
        ])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["science-fiction"]),
            book("2", genres: ["roman policier"]),
            book("3", genres: ["science-fiction"])
        ])

        #expect(plan.shelves.count == 2)
        #expect(plan.shelves[0].name == "Littérature de l'imaginaire")
        #expect(plan.shelves[0].books.map(\.id) == ["1", "3"])
        #expect(plan.shelves[1].name == "Romans policiers")
        #expect(plan.shelves[1].books.map(\.id) == ["2"])
        #expect(plan.leftUnshelved.isEmpty)
    }

    @Test func severalGenresCanShareOneShelf() throws {
        let mapping: ValidatedGenreMapping = try mapping([
            ("science-fiction", "Littérature de l'imaginaire"),
            ("fantasy", "Littérature de l'imaginaire")
        ])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["science-fiction"]),
            book("2", genres: ["fantasy"])
        ])

        #expect(plan.shelves.count == 1)
        #expect(plan.shelves[0].bookCount == 2)
    }

    @Test func shelvesFollowTheOrderPhaseOneDeclaredThemIn() throws {
        let mapping: ValidatedGenreMapping = try mapping([
            ("essai", "Essais et documents"),
            ("roman policier", "Romans policiers"),
            ("science-fiction", "Littérature de l'imaginaire")
        ])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["essai"]),
            book("2", genres: ["roman policier"]),
            book("3", genres: ["science-fiction"])
        ])

        #expect(plan.shelves.map(\.name) == taxonomy)
    }

    /// Same rule as the histogram, asserted on the other side: a copy carrying
    /// several genres is filed once, under the first. A book on two proposed
    /// étagères would be filed twice by issue 0024.
    @Test func aBookWithSeveralGenresIsFiledOnceUnderItsFirst() throws {
        let mapping: ValidatedGenreMapping = try mapping([
            ("science-fiction", "Littérature de l'imaginaire"),
            ("essai", "Essais et documents")
        ])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["science-fiction", "essai"])
        ])

        #expect(plan.shelves.count == 1)
        #expect(plan.shelves[0].name == "Littérature de l'imaginaire")
        #expect(plan.shelvedBookCount == 1)
    }

    // MARK: - Books the plan leaves alone

    @Test func booksWithNoGenreAreLeftOut() throws {
        let mapping: ValidatedGenreMapping = try mapping([("essai", "Essais et documents")])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["essai"]),
            book("2"),
            book("3", genres: ["  "])
        ])

        #expect(plan.shelvedBookCount == 1)
        #expect(plan.leftUnshelved.map(\.id) == ["2", "3"])
    }

    /// Not defaulted to the first shelf, not swept into a catch-all: filing on a
    /// guess is exactly what this design refuses to do.
    @Test func aBookWhoseGenreIsAbsentFromTheMappingIsLeftOutRatherThanDefaulted() throws {
        let mapping: ValidatedGenreMapping = try mapping([("essai", "Essais et documents")])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["essai"]),
            book("2", genres: ["poésie"])
        ])

        #expect(plan.shelves.count == 1)
        #expect(plan.shelves[0].books.map(\.id) == ["1"])
        #expect(plan.leftUnshelved.map(\.id) == ["2"])
    }

    @Test func leftOutBooksKeepTheOrderTheyCameIn() throws {
        let mapping: ValidatedGenreMapping = try mapping([("essai", "Essais et documents")])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("9"),
            book("1", genres: ["essai"]),
            book("5")
        ])

        #expect(plan.leftUnshelved.map(\.id) == ["9", "5"])
    }

    // MARK: - Counts and empties

    @Test func theCountOnEachShelfMatchesWhatIsOnIt() throws {
        let mapping: ValidatedGenreMapping = try mapping([
            ("science-fiction", "Littérature de l'imaginaire"),
            ("roman policier", "Romans policiers")
        ])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["science-fiction"]),
            book("2", genres: ["science-fiction"]),
            book("3", genres: ["roman policier"])
        ])

        for shelf in plan.shelves {
            #expect(shelf.bookCount == shelf.books.count)
        }
        #expect(plan.shelvedBookCount == 3)
        #expect(plan.shelvedBookCount == plan.shelves.reduce(0) { $0 + $1.books.count })
    }

    @Test func aShelfThatWouldEndUpEmptyIsDropped() throws {
        let mapping: ValidatedGenreMapping = try mapping([
            ("science-fiction", "Littérature de l'imaginaire"),
            ("roman policier", "Romans policiers"),
            ("essai", "Essais et documents")
        ])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["science-fiction"])
        ])

        #expect(plan.shelves.map(\.name) == ["Littérature de l'imaginaire"])
    }

    @Test func aDeclaredShelfNoGenreMapsToNeverAppears() throws {
        let mapping: ValidatedGenreMapping = try mapping([
            ("science-fiction", "Littérature de l'imaginaire")
        ])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [
            book("1", genres: ["science-fiction"])
        ])

        #expect(mapping.shelfNames.count == 3)
        #expect(plan.shelves.count == 1)
    }

    @Test func aPlanWithNoBookAtAllProposesNothing() throws {
        let mapping: ValidatedGenreMapping = try mapping([("essai", "Essais et documents")])
        let plan: AutoSortPlan = .init(mapping: mapping, books: [])

        #expect(plan.isEmpty)
        #expect(plan.shelvedBookCount == 0)
        #expect(plan.leftUnshelved.isEmpty)
    }

    // MARK: - Nothing to propose

    @Test func theNothingToProposePlanKeepsEveryBookUnshelved() {
        let books: [AutoSortBook] = [book("1"), book("2")]
        let plan: AutoSortPlan = .init(nothingToPropose: books)

        #expect(plan.isEmpty)
        #expect(plan.shelvedBookCount == 0)
        #expect(plan.leftUnshelved.map(\.id) == ["1", "2"])
    }
}
