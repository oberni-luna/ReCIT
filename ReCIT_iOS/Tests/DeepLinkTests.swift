//
//  DeepLinkTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 15/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("DeepLink")
struct DeepLinkTests {

    @Test
    func `an entity link carries its uri whatever its prefix`() throws {
        let isbn: URL = try #require(URL(string: "https://link.exlibris.lunabee.ovh/entity/isbn:9782070360024"))
        let wikidata: URL = try #require(URL(string: "https://link.exlibris.lunabee.ovh/entity/wd:Q535"))

        #expect(DeepLink(url: isbn) == .entity(uri: "isbn:9782070360024"))
        #expect(DeepLink(url: wikidata) == .entity(uri: "wd:Q535"))
    }

    @Test
    func `another host another path or a uri without a prefix is not a link`() throws {
        let urls: [String] = [
            "https://inventaire.io/entity/wd:Q535",
            "http://link.exlibris.lunabee.ovh/entity/wd:Q535",
            "https://link.exlibris.lunabee.ovh/users/olivier",
            "https://link.exlibris.lunabee.ovh/entity/Q535",
            "https://link.exlibris.lunabee.ovh/entity/wd:",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q535/edit",
            "https://link.exlibris.lunabee.ovh/",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q1%7Cwd:Q2",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q1%26autocreate=true",
            "https://link.exlibris.lunabee.ovh/entity/foo:bar"
        ]

        for string in urls {
            let url: URL = try #require(URL(string: string))
            #expect(DeepLink(url: url) == nil, "\(string)")
        }
    }

    @Test
    func `a link falls back to the same page on inventaire.io`() {
        #expect(DeepLink.entity(uri: "wd:Q535").webURL?.absoluteString == "https://inventaire.io/entity/wd:Q535")
    }

    @Test
    func `an isbn opens its book without asking inventaire.io and nothing else does`() {
        #expect(NavigationDestination(linkedISBN: "isbn:9782070360024") == .book(anchor: .edition(uri: "isbn:9782070360024")))
        #expect(NavigationDestination(linkedISBN: "wd:Q535") == nil)
    }

    @Test
    func `an edition opens its book a work the book of its best edition a person their screen`() {
        #expect(NavigationDestination(linkedEntity: .mock(uri: "inv:abc", type: "edition")) == .book(anchor: .edition(uri: "inv:abc")))
        #expect(
            NavigationDestination(linkedEntity: .mock(uri: "wd:Q1", type: "work"))
                == .book(anchor: .bestEditionOfWork(uri: "wd:Q1", title: "Titre", imageUrl: nil))
        )
        #expect(NavigationDestination(linkedEntity: .mock(uri: "wd:Q535", type: "human")) == .author(uri: "wd:Q535"))
        #expect(NavigationDestination(linkedEntity: .mock(uri: "wd:Q2", type: "serie")) == nil)
        #expect(NavigationDestination(linkedEntity: .mock(uri: "wd:Q3", type: nil)) == nil)
    }
}
