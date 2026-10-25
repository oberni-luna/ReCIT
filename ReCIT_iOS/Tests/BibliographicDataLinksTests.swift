//
//  BibliographicDataLinksTests.swift
//  ReCIT_iOSTests
//
//  The three places the help about bibliographic data points to — the same ones
//  inventaire.io's own notice gives.
//
//  See PRD 0026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("BibliographicDataLinks")
struct BibliographicDataLinksTests {

    @Test("My contributions are under my username on the website")
    func contributionsUnderTheUsername() {
        let url: URL? = BibliographicDataLinks.contributions(username: "OlivierB", baseUrl: "https://inventaire.io")

        #expect(url?.absoluteString == "https://inventaire.io/users/OlivierB/contributions")
    }

    @Test("A username that is not a path segment as it is goes out encoded")
    func contributionsEncodeTheUsername() {
        let url: URL? = BibliographicDataLinks.contributions(username: "Olivier B", baseUrl: "https://inventaire.io")

        #expect(url?.absoluteString == "https://inventaire.io/users/Olivier%20B/contributions")
    }

    @Test("The wiki and the chat are the ones inventaire.io links to")
    func wikiAndChat() {
        #expect(BibliographicDataLinks.wiki?.absoluteString == "https://wiki.inventaire.io/wiki/Entities_data")
        #expect(BibliographicDataLinks.chat?.host() == "app.element.io")
    }
}
