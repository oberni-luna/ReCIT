//
//  SearchResult+Edition.swift
//  ReCIT_iOS
//
//  The one result an ISBN typed in Recherche brings back: the edition it names, drawn like a
//  book among the others — its cover, its title, and who wrote it and who published it.
//
//  See `IsbnQuery`.
//

import Foundation

extension SearchResult {
    init(edition: Edition) {
        let byline: [String] = [
            edition.authorNames.isEmpty ? nil : edition.authorNames.formatted(.list(type: .and)),
            edition.publisherName,
        ]
        .compactMap { $0 }

        self.init(
            id: edition.uri,
            uri: edition.uri,
            title: edition.title,
            description: byline.isEmpty ? nil : byline.joined(separator: " · "),
            imageUrl: edition.image,
            score: 1,
            type: .editions
        )
    }
}
