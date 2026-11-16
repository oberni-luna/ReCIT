//
//  ListElementEntity.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

/// The work or the author a list element points to, as the store holds it: what the cover
/// flow's title and the element's « Partager » call it.
enum ListElementEntity {
    case work(Work)
    case author(Author)

    var title: String {
        switch self {
        case let .work(work): work.title
        case let .author(author): author.name
        }
    }

    /// Under the title: the work's authors, else its subtitle — or, for an author, what
    /// inventaire.io says they are.
    var byline: String? {
        switch self {
        case let .work(work):
            let names: [String] = work.authors.map(\.name).filter { $0.isEmpty == false }
            return names.isEmpty ? work.subtitle : names.joined(separator: ", ")
        case let .author(author):
            return author.subtitle
        }
    }
}
