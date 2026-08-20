//
//  GenreHistogramTests.swift
//  ReCIT_iOSTests
//
//  Phase 1's input, asserted. Pure and network-free, like the shelf layout suite —
//  no model, no store, no SwiftUI.
//
//  Two things here are load-bearing and invisible on screen. The counts are what
//  let the model fold a three-book genre into a broader étagère, so a count that
//  double-counts a book carrying two genres would inflate a niche genre above its
//  real weight and produce a shelf nobody wants. And the unclassified tally is the
//  pile that stays unshelved: dropped silently, it would look like the library
//  simply had fewer books. See PRD 0006.
//

import Testing
@testable import ReCIT_iOS

@Suite("GenreHistogram")
struct GenreHistogramTests {

    private func book(_ id: String, genres: [String] = []) -> AutoSortBook {
        .init(id: id, title: "Livre \(id)", genres: genres)
    }

    // MARK: - Distinct genres and counts

    @Test func countsBooksPerDistinctGenre() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["science-fiction"]),
            book("2", genres: ["science-fiction"]),
            book("3", genres: ["poésie"])
        ])

        #expect(histogram.entries.count == 2)
        #expect(histogram.entries[0].genre == "science-fiction")
        #expect(histogram.entries[0].count == 2)
        #expect(histogram.entries[1].genre == "poésie")
        #expect(histogram.entries[1].count == 1)
    }

    @Test func ordersHeaviestGenreFirst() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["poésie"]),
            book("2", genres: ["science-fiction"]),
            book("3", genres: ["science-fiction"])
        ])

        #expect(histogram.genres == ["science-fiction", "poésie"])
    }

    /// Equal counts must not reorder between runs: the same library has to produce
    /// the same prompt, or the taxonomy drifts for no reason at all.
    @Test func breaksCountTiesAlphabeticallySoThePromptIsStable() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["roman policier"]),
            book("2", genres: ["essai"]),
            book("3", genres: ["fantasy"])
        ])

        #expect(histogram.genres == ["essai", "fantasy", "roman policier"])
    }

    // MARK: - Books with no genre

    @Test func booksWithNoGenreAreExcludedFromTheHistogramButCounted() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["essai"]),
            book("2"),
            book("3")
        ])

        #expect(histogram.entries.map(\.genre) == ["essai"])
        #expect(histogram.unclassifiedCount == 2)
        #expect(histogram.classifiedCount == 1)
    }

    @Test func aBlankGenreLabelCountsAsNoGenre() {
        let histogram: GenreHistogram = .init(books: [book("1", genres: ["   ", ""])])

        #expect(histogram.isEmpty)
        #expect(histogram.unclassifiedCount == 1)
    }

    // MARK: - Several genres on one book

    /// The chosen rule: a book is filed under its *first* genre and counted once.
    /// Counting it under each would make the histogram a tally of claims rather than
    /// of books, which is not what phase 1 is being asked to size shelves against.
    @Test func aBookWithSeveralGenresCountsOnceUnderItsFirst() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["science-fiction", "roman d'aventures", "dystopie"])
        ])

        #expect(histogram.entries.count == 1)
        #expect(histogram.entries[0].genre == "science-fiction")
        #expect(histogram.entries[0].count == 1)
    }

    @Test func classifiedCountAlwaysEqualsTheSumOfTheEntries() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["fantasy", "science-fiction"]),
            book("2", genres: ["fantasy"]),
            book("3"),
            book("4", genres: ["essai", "histoire"])
        ])

        #expect(histogram.classifiedCount == 3)
        #expect(histogram.classifiedCount == histogram.entries.reduce(0) { $0 + $1.count })
        #expect(histogram.unclassifiedCount == 1)
    }

    /// A leading blank label must not make the book look unclassified — the first
    /// *usable* genre is the primary one.
    @Test func aLeadingBlankLabelIsSkippedRatherThanFilingTheBookNowhere() {
        let histogram: GenreHistogram = .init(books: [book("1", genres: ["", "théâtre"])])

        #expect(histogram.genres == ["théâtre"])
        #expect(histogram.unclassifiedCount == 0)
    }

    // MARK: - Spelling drift

    @Test func caseAndAccentDifferingLabelsCollapseOntoTheFirstSpelling() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["Poésie"]),
            book("2", genres: ["poesie"]),
            book("3", genres: ["POÉSIE"])
        ])

        #expect(histogram.entries.count == 1)
        #expect(histogram.entries[0].genre == "Poésie")
        #expect(histogram.entries[0].count == 3)
    }

    @Test func surroundingWhitespaceDoesNotSplitAGenre() {
        let histogram: GenreHistogram = .init(books: [
            book("1", genres: ["essai"]),
            book("2", genres: ["  essai "])
        ])

        #expect(histogram.entries.count == 1)
        #expect(histogram.entries[0].count == 2)
    }

    // MARK: - Nothing to sort

    @Test func anEmptyInventoryYieldsAnEmptyHistogramRatherThanFailing() {
        let histogram: GenreHistogram = .init(books: [])

        #expect(histogram.isEmpty)
        #expect(histogram.entries.isEmpty)
        #expect(histogram.genres.isEmpty)
        #expect(histogram.unclassifiedCount == 0)
        #expect(histogram.classifiedCount == 0)
    }

    @Test func anInventoryWithNoGenreAtAllIsEmptyButNotSilent() {
        let histogram: GenreHistogram = .init(books: [book("1"), book("2")])

        #expect(histogram.isEmpty)
        #expect(histogram.unclassifiedCount == 2)
    }
}
