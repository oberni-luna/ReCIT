//
//  EditionWork.swift
//  ReCIT_iOS
//
//  A work an edition is an edition of, as inventaire.io holds it: its title and its authors. One
//  the edition had when the form opened, one picked from the search, or one just created. What
//  the form changes about it is a `WorkEdit`.
//
//  Its authors can be added to only when it is one of inventaire.io's own (`inv:`): a Wikidata
//  work's authors are edited on Wikidata, through an account this app does not hold.
//

import Foundation

struct EditionWork: Equatable, Sendable {
    let uri: String
    var title: String
    /// Who wrote it. Read from the server, each carries its uri; picked from the search, only
    /// its name — the search answers names.
    var authors: [NewBookAuthor]
    /// The picture the row shows.
    var imageUrl: String?
    /// The language of the label shown as its title: the one a new title is written in.
    var titleLanguage: String?

    init(
        uri: String,
        title: String,
        authors: [NewBookAuthor] = [],
        imageUrl: String? = nil,
        titleLanguage: String? = nil
    ) {
        self.uri = uri
        self.title = title
        self.authors = authors
        self.imageUrl = imageUrl
        self.titleLanguage = titleLanguage
    }

    /// A work picked from the search.
    init(candidate: WorkCandidate) {
        self.init(
            uri: candidate.uri,
            title: candidate.title,
            authors: candidate.authors.map { NewBookAuthor(name: $0) },
            imageUrl: candidate.imageUrl
        )
    }

    var isEditable: Bool {
        uri.hasPrefix("inv:")
    }

    /// The work as `WorkRow` draws it: its title, and its authors on the line under it.
    var candidate: WorkCandidate {
        .init(
            uri: uri,
            title: title,
            authors: authors.map(\.trimmedName).filter { $0.isEmpty == false },
            year: nil,
            summary: nil,
            imageUrl: imageUrl
        )
    }
}
