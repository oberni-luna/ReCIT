//
//  WorkCandidate.swift
//  ReCIT_iOS
//
//  A work the search proposed for the book being created: enough to recognise it — its cover,
//  its title, who wrote it and when — and the uri that names it once the reader picks it.
//
//  A value, not a `Work`. A search result is shown and forgotten, and inserting every candidate
//  into the store would leave a trail of works nobody asked for. Only the one picked travels, in
//  the draft, and only its uri reaches the server.
//
//  See PRD 0026.
//

import Foundation

struct WorkCandidate: Hashable, Identifiable, Sendable {
    let uri: String
    let title: String

    var id: String { uri }

    /// Who wrote it, by name. Empty when the work names nobody, or when the names could not be
    /// read — in which case `summary` stands in.
    let authors: [String]

    /// The year it came out, as four digits.
    let year: String?

    /// What the search said about the work, kept for when neither its authors nor its year are
    /// known: a Wikidata description often names both anyway.
    let summary: String?

    let imageUrl: String?

    /// The candidate a stored work makes: the one the reconnaissance pass recognised, drawn as
    /// the search's results are.
    init(work: Work) {
        self.init(
            uri: work.uri,
            title: work.title,
            authors: work.authors.map(\.name),
            year: work.publicationDate.map { String(Calendar.current.component(.year, from: $0)) },
            summary: work.subtitle,
            imageUrl: work.image
        )
    }

    init(
        uri: String,
        title: String,
        authors: [String],
        year: String?,
        summary: String?,
        imageUrl: String?
    ) {
        self.uri = uri
        self.title = title
        self.authors = authors
        self.year = year
        self.summary = summary
        self.imageUrl = imageUrl
    }

    /// The line under the title: « Kim Stanley Robinson · 2020 », or the search's description.
    var detail: String? {
        Self.byline(authors: authors, year: year) ?? summary
    }

    /// Authors and year, each half optional. Both missing answers `nil`, so the caller can fall
    /// back to whatever else it has.
    static func byline(authors: [String], year: String?) -> String? {
        let names: String? = authors.isEmpty ? nil : authors.joined(separator: ", ")
        let parts: [String] = [names, year].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The year of a `wdt:P577` value — `2020` from `2020-10-06`, from `2020-10` and from `2020`.
    /// Anything that does not open on four digits answers `nil`: a date before the common era is
    /// written `-0500`, and is not a year worth printing under a book.
    static func year(of date: String?) -> String? {
        guard let date else { return nil }

        let prefix: Substring = date.prefix(4)
        guard prefix.count == 4, prefix.allSatisfy(\.isNumber) else { return nil }

        return String(prefix)
    }

    /// The candidates for a search, in the search's order, each completed by what a `by-uris`
    /// call answered about it: its authors' names and its publication date.
    ///
    /// `entities` holds the works **and** their authors — `relatives=wdt:P50` puts both in the
    /// same envelope — so an author's name is read from the same dictionary as the work that
    /// names them. A work the call said nothing about keeps the search's description.
    static func candidates(
        from results: [SearchResult],
        entities: [String: WorkSummaryDTO]
    ) -> [WorkCandidate] {
        results.map { result in
            let work: WorkSummaryDTO? = entities[result.uri]
            let authors: [String] = work?.values(of: .author).compactMap { entities[$0]?.label } ?? []

            return .init(
                uri: result.uri,
                title: result.title,
                authors: authors,
                year: year(of: work?.values(of: .publicationDate).first),
                summary: result.description,
                imageUrl: result.imageUrl
            )
        }
    }
}
