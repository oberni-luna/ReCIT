//
//  BookshopTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 07/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct BookshopTests {
    @Test
    func `searches Chez mon libraire by title then author, accents and spaces encoded`() throws {
        let url: URL = try #require(Bookshop.chezMonLibraire.searchURL(title: "Petit pays", authorName: "Gaël Faye"))

        #expect(url.absoluteString == "https://www.chez-mon-libraire.fr/listeliv.php?mots_recherche=Petit%20pays%20Ga%C3%ABl%20Faye")
    }

    @Test
    func `searches Recyclivre by title then author, accents and spaces encoded`() throws {
        let url: URL = try #require(Bookshop.recyclivre.searchURL(title: "L’Étranger", authorName: "Albert Camus"))

        #expect(url.absoluteString == "https://www.recyclivre.com/search?q=L%E2%80%99%C3%89tranger%20Albert%20Camus")
    }

    @Test
    func `searches by the title alone when the work has no author`() throws {
        let withoutAuthor: URL = try #require(Bookshop.recyclivre.searchURL(title: "Beowulf", authorName: nil))
        let blankAuthor: URL = try #require(Bookshop.recyclivre.searchURL(title: "Beowulf", authorName: "  "))

        #expect(withoutAuthor.absoluteString == "https://www.recyclivre.com/search?q=Beowulf")
        #expect(blankAuthor == withoutAuthor)
    }

    @Test
    func `trims the title and the author`() throws {
        let url: URL = try #require(Bookshop.recyclivre.searchURL(title: " Petit pays\n", authorName: " Gaël Faye "))

        #expect(url.absoluteString == "https://www.recyclivre.com/search?q=Petit%20pays%20Ga%C3%ABl%20Faye")
    }

    @Test
    func `encodes the characters a query would otherwise split on`() throws {
        let url: URL = try #require(Bookshop.chezMonLibraire.searchURL(title: "C++ & Java = ?", authorName: nil))
        let components: URLComponents = try #require(.init(url: url, resolvingAgainstBaseURL: false))

        #expect(url.absoluteString == "https://www.chez-mon-libraire.fr/listeliv.php?mots_recherche=C%2B%2B%20%26%20Java%20%3D%20?")
        #expect(components.queryItems == [.init(name: "mots_recherche", value: "C++ & Java = ?")])
    }
}
