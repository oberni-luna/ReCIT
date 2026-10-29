//
//  EditionFacts.swift
//  ReCIT_iOS
//
//  What the duplicate detection knows of one edition, read once off the `@Model` so the rules
//  never touch SwiftData and can be tested on plain values.
//
//  `mergeUri` is the `inv:` uri a merge takes as `from`; `nil` for a Wikidata edition, which can
//  only be kept. `reportedMergeTargets` are the editions inventaire.io has an open merge task
//  for, this one being the edition that would disappear. PRD 0028.
//

import Foundation

nonisolated struct EditionFacts: Equatable, Hashable, Sendable {
    let uri: String
    let mergeUri: String?
    let isbn: String?
    let publisherUri: String?
    let year: String?
    let differentFrom: Set<String>
    let reportedMergeTargets: Set<String>
    /// One point per datum the edition carries — what « the most complete » means.
    let completeness: Int

    init(
        uri: String,
        mergeUri: String?,
        isbn: String? = nil,
        publisherUri: String? = nil,
        year: String? = nil,
        differentFrom: Set<String> = [],
        reportedMergeTargets: Set<String> = [],
        completeness: Int = 0
    ) {
        self.uri = uri
        self.mergeUri = mergeUri
        self.isbn = IsbnNormalization.normalized(isbn)
        self.publisherUri = publisherUri
        self.year = year
        self.differentFrom = differentFrom
        self.reportedMergeTargets = reportedMergeTargets
        self.completeness = completeness
    }

    @MainActor
    init(edition: Edition) {
        let data: [Bool] = [
            edition.isbn != nil,
            edition.image?.isEmpty == false,
            edition.numberOfPages != nil,
            edition.publisherUri != nil,
            edition.publicationDate != nil,
            edition.subtitle?.isEmpty == false,
            edition.lang?.isEmpty == false
        ]
        self.init(
            uri: edition.uri,
            mergeUri: edition.uri.hasPrefix("wd:") ? nil : (edition.invUri ?? (edition.uri.hasPrefix("inv:") ? edition.uri : nil)),
            isbn: edition.isbn,
            publisherUri: edition.publisherUri,
            year: edition.publicationYear,
            differentFrom: Set(edition.differentFromUris),
            reportedMergeTargets: Set(edition.pendingMergeTargetUris),
            completeness: data.filter { $0 }.count
        )
    }

    /// Both uris this edition goes by, for matching a claim or a task written with either.
    var uris: Set<String> {
        Set([uri, mergeUri].compactMap { $0 })
    }

    var isWikidata: Bool {
        uri.hasPrefix("wd:")
    }
}
