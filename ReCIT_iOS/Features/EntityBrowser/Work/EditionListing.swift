//
//  EditionListing.swift
//  ReCIT_iOS
//
//  What « Éditions » lists, worked out once per change rather than at every render: the order
//  of the editions and their duplicates. A work can have thousands of editions — « L'Appel de
//  la forêt » has 7742 on inventaire.io —, too many to sort and compare in `body`, so `make`
//  takes plain values read off the `@Model`s and runs off the main actor.
//
//  See PRD 0028.
//

import Foundation

nonisolated struct EditionListing: Equatable, Sendable {
    /// What the order reads of an edition.
    nonisolated struct Entry: Equatable, Sendable {
        let uri: String
        let year: String?
        let title: String

        init(
            uri: String,
            year: String?,
            title: String
        ) {
            self.uri = uri
            self.year = year
            self.title = title
        }

        @MainActor
        init(edition: Edition) {
            self.init(
                uri: edition.uri,
                year: edition.publicationYear,
                title: edition.title
            )
        }
    }

    /// The uris of the editions, in the order the list shows them.
    let order: [String]
    let duplicates: EditionDuplicates

    static func make(entries: [Entry], facts: [EditionFacts]) -> EditionListing {
        .init(
            order: entries.sorted(by: listOrder).map(\.uri),
            duplicates: EditionDuplicateDetector.detect(facts)
        )
    }

    /// `make`, away from the main actor.
    @concurrent
    static func computed(entries: [Entry], facts: [EditionFacts]) async -> EditionListing {
        make(entries: entries, facts: facts)
    }

    /// Oldest first, as a publication history reads; an edition without a date last; then by
    /// title, then by uri, so the order never moves between two visits.
    static func listOrder(_ lhs: Entry, _ rhs: Entry) -> Bool {
        switch (lhs.year, rhs.year) {
        case let (left?, right?) where left != right:
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            let titles: ComparisonResult = lhs.title.localizedStandardCompare(rhs.title)
            return titles == .orderedSame ? lhs.uri < rhs.uri : titles == .orderedAscending
        }
    }
}
