//
//  GenreHistogram.swift
//  ReCIT_iOS
//
//  Phase 1's entire input: the distinct genres in the unshelved books, with how
//  many books each holds.
//
//  The counts are not decoration. They are the reason the model can fold a
//  three-book genre into a broader étagère instead of proposing a three-book
//  shelf, and they are what makes this input small at any library size — a
//  three-thousand-book collection has no more distinct genres than a
//  three-hundred-book one, so the cost of a run is bounded by genres, not books.
//
//  Books with no genre are counted apart rather than dropped silently: they are
//  the pile that stays unshelved, and the user is owed a number for it.
//
//  Pure by design — no store, no model, no SwiftUI. See PRD 0006.
//

import Foundation

struct GenreHistogram: Equatable, Sendable {

    /// One genre and its weight in the collection.
    struct Entry: Identifiable, Equatable, Sendable {
        /// The label as first written in the data — what the prompt shows.
        let genre: String
        /// The comparison identity the label groups on.
        let key: String
        /// Books filed under this genre, each counted once.
        let count: Int

        var id: String { key }
    }

    /// Heaviest genre first, ties broken alphabetically. Ordered rather than a
    /// dictionary so the prompt is stable across runs — the same library must not
    /// produce a differently ordered prompt, or the taxonomy drifts for no reason
    /// — and so the model reads the collection's shape top-down.
    let entries: [Entry]

    /// Books whose genre enrichment came back empty. They stay unshelved; nothing
    /// guesses for them.
    let unclassifiedCount: Int

    var isEmpty: Bool { entries.isEmpty }

    /// Books that do carry a genre. Equal to the sum of the entry counts, because
    /// each book is counted exactly once (see `AutoSortBook.primaryGenre`).
    var classifiedCount: Int {
        entries.reduce(0) { $0 + $1.count }
    }

    /// The distinct genre labels, heaviest first — phase 2's input.
    var genres: [String] { entries.map(\.genre) }

    /// Tallies a set of books. An empty inventory yields an empty histogram rather
    /// than failing: "you have nothing to sort" is an answer, not an error.
    init(books: [AutoSortBook]) {
        var counts: [String: Int] = [:]
        var labels: [String: String] = [:]
        var unclassified: Int = 0

        for book in books {
            guard let genre = book.primaryGenre, let key = book.primaryGenreKey else {
                unclassified += 1
                continue
            }
            counts[key, default: 0] += 1
            // First spelling seen wins, so two case-differing labels collapse to
            // one genre named the way the data first named it.
            if labels[key] == nil {
                labels[key] = genre
            }
        }

        entries = counts
            .map { Entry(genre: labels[$0.key] ?? $0.key, key: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.genre < rhs.genre : lhs.count > rhs.count
            }
        unclassifiedCount = unclassified
    }
}
