//
//  AutoSortBook.swift
//  ReCIT_iOS
//
//  One unshelved copy, reduced to what the auto-sort pipeline actually needs. A
//  value type rather than an `InventoryItem` so the histogram, the validator and
//  the assignment can be exercised without a store, a network or a model — which
//  is the whole point of splitting them out. The impure layer maps items in.
//
//  It carries the cover and the authors only so the review screen can show a book
//  the user recognises; no phase reads them, and the model is never shown any of
//  this. See PRD 0006.
//

import Foundation

struct AutoSortBook: Identifiable, Equatable, Sendable {

    /// The item's server `_id`. Issue 0024 files by this, so it is the identity.
    let id: String
    let title: String
    let authors: String
    let coverImageUrl: String?

    /// Every genre label resolved for the work(s) behind this copy, in the order
    /// Wikidata claimed them.
    let genres: [String]

    init(
        id: String,
        title: String,
        authors: String = "",
        coverImageUrl: String? = nil,
        genres: [String] = []
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.coverImageUrl = coverImageUrl
        self.genres = genres
    }

    /// **The multi-genre rule.** A copy carrying several genres is filed under the
    /// first one, and counted once.
    ///
    /// A book must land on exactly one étagère: the plan is a partition, and a copy
    /// duplicated across two proposed shelves would be filed twice by issue 0024
    /// and read as a bug on the review screen. Wikidata's `wdt:P136` claims come
    /// back most-significant first, so the first label is the closest thing to a
    /// primary genre the data offers — and taking the first keeps the histogram's
    /// counts equal to a number of *books*, which is exactly what phase 1 is being
    /// asked to size shelves against. Counting a book under each of its genres
    /// would inflate a niche genre above its real weight.
    ///
    /// Blank labels are skipped rather than accepted, so a stray empty string does
    /// not make a book look classified.
    var primaryGenre: String? {
        genres.lazy.compactMap(AutoSortName.trimmed).first
    }

    /// The primary genre's comparison identity, for grouping and lookup.
    var primaryGenreKey: String? {
        genres.lazy.compactMap(AutoSortName.key).first
    }
}
