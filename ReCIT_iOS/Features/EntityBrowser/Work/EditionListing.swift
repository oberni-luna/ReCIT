//
//  EditionListing.swift
//  ReCIT_iOS
//
//  What « Éditions » lists, worked out once per change rather than at every render: the
//  language shown and the menu that changes it, the order of the editions in that language, and
//  their duplicates. A work can have thousands of editions — « L'Appel de la forêt » has 7742 on
//  inventaire.io —, too many to sort and compare in `body`, so `make` takes plain values read off
//  the `@Model`s and runs off the main actor.
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
        let lang: String?

        init(
            uri: String,
            year: String?,
            title: String,
            lang: String? = nil
        ) {
            self.uri = uri
            self.year = year
            self.title = title
            self.lang = lang
        }

        @MainActor
        init(edition: Edition) {
            self.init(
                uri: edition.uri,
                year: edition.publicationYear,
                title: edition.title,
                lang: edition.lang
            )
        }
    }

    /// The language shown: the one picked, or the phone's until somebody picks one.
    let language: EditionLanguageFilter
    /// What the language menu offers, counted over every edition.
    let options: [EditionLanguageFilterOption]
    /// The uris of the editions in `language`, in the order the list shows them.
    let order: [String]
    /// The duplicates among the editions in `language` only: the banner and « Les comparer »
    /// speak of the list on screen.
    let duplicates: EditionDuplicates

    /// `chosen` is the language picked in the menu, `nil` until one is.
    static func make(
        entries: [Entry],
        facts: [EditionFacts],
        chosen: EditionLanguageFilter? = .all,
        phoneLanguage: String? = nil
    ) -> EditionListing {
        let options: [EditionLanguageFilterOption] = EditionLanguageFilter.options(of: entries.map(\.lang))
        let language: EditionLanguageFilter = chosen ?? EditionLanguageFilter.preferred(phoneLanguage, among: options)
        let shown: [Entry] = entries.filter { language.admits($0.lang) }
        let shownUris: Set<String> = .init(shown.map(\.uri))
        return .init(
            language: language,
            options: options,
            order: shown.sorted(by: listOrder).map(\.uri),
            duplicates: EditionDuplicateDetector.detect(facts.filter { shownUris.contains($0.uri) })
        )
    }

    /// `make`, away from the main actor.
    @concurrent
    static func computed(
        entries: [Entry],
        facts: [EditionFacts],
        chosen: EditionLanguageFilter?,
        phoneLanguage: String?
    ) async -> EditionListing {
        make(entries: entries, facts: facts, chosen: chosen, phoneLanguage: phoneLanguage)
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
