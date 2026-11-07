//
//  Bookshop.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import Foundation

/// A site where a work can be found outside the reader's network, searched by its title and its
/// author — never by an ISBN: a list holds a work, and the site then shows every edition it stocks.
nonisolated enum Bookshop: CaseIterable, Sendable {
    /// Second-hand books.
    case recyclivre
    /// Independent bookshops, which reserve a copy near the reader.
    case chezMonLibraire

    private var host: String {
        switch self {
        case .recyclivre: "www.recyclivre.com"
        case .chezMonLibraire: "www.chez-mon-libraire.fr"
        }
    }

    private var path: String {
        switch self {
        case .recyclivre: "/search"
        case .chezMonLibraire: "/listeliv.php"
        }
    }

    private var queryName: String {
        switch self {
        case .recyclivre: "q"
        case .chezMonLibraire: "mots_recherche"
        }
    }

    /// « Petit pays Gaël Faye »: the title, then the author's name when there is one.
    private static func query(
        title: String,
        authorName: String?
    ) -> String {
        [title, authorName ?? ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }

    /// The site's search for a work.
    /// - Parameters:
    ///   - title: the work's title.
    ///   - authorName: its first author's name, if it has one.
    /// - Returns: the address of the search, encoded.
    func searchURL(
        title: String,
        authorName: String?
    ) -> URL? {
        var components: URLComponents = .init()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = [
            .init(name: queryName, value: Self.query(title: title, authorName: authorName))
        ]
        // `URLComponents` leaves a `+` as it is, which the site would read as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacing("+", with: "%2B")
        return components.url
    }
}
