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
    private static let listId: String = "88b00676d608d9d53c5974fd9bc1009a"
    private static let elementId: String = "88b00676d608d9d53c5974fd9bc8a871"
    private static let itemId: String = "d3e1127cfc074506949a3c9396e4bccb"
    private static let shelfId: String = "2b8c1752cc1195dafc3a8910f80822df"

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
            "https://link.exlibris.lunabee.ovh/shelves/olivier",
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
    func `a reader link carries the username as typed`() throws {
        let urls: [String: String] = [
            "https://link.exlibris.lunabee.ovh/users/OlivierB_test4": "OlivierB_test4",
            "https://link.exlibris.lunabee.ovh/users/maxlath": "maxlath",
            "https://link.exlibris.lunabee.ovh/users/Ana%C3%AFs": "Anaïs",
            "https://link.exlibris.lunabee.ovh/users/ab": "ab"
        ]

        for (string, username) in urls {
            let url: URL = try #require(URL(string: string))
            #expect(DeepLink(url: url) == .user(username: username), "\(string)")
        }
    }

    @Test
    func `a group link carries its slug`() throws {
        let urls: [String: String] = [
            "https://link.exlibris.lunabee.ovh/groups/le-club-de-lecture": "le-club-de-lecture",
            "https://link.exlibris.lunabee.ovh/groups/le-club-de-lecture.2": "le-club-de-lecture.2",
            "https://link.exlibris.lunabee.ovh/groups/lecture-%C3%A0-chamb%C3%A9ry": "lecture-à-chambéry"
        ]

        for (string, slug) in urls {
            let url: URL = try #require(URL(string: string))
            #expect(DeepLink(url: url) == .group(slug: slug), "\(string)")
        }
    }

    @Test
    func `a username or a slug outside inventaire.io's rule is not a link`() throws {
        let urls: [String] = [
            "https://link.exlibris.lunabee.ovh/users/a%7Cb",
            "https://link.exlibris.lunabee.ovh/users/a%26usernames=b",
            "https://link.exlibris.lunabee.ovh/users/a",
            "https://link.exlibris.lunabee.ovh/users/abcdefghijklmnopqrstu",
            "https://link.exlibris.lunabee.ovh/users/max.lath",
            "https://link.exlibris.lunabee.ovh/users/max-lath",
            "https://link.exlibris.lunabee.ovh/users/maxlath/inventory",
            "https://link.exlibris.lunabee.ovh/users",
            "http://link.exlibris.lunabee.ovh/users/maxlath",
            "https://inventaire.io/users/maxlath",
            "https://link.exlibris.lunabee.ovh/groups/a%26b",
            "https://link.exlibris.lunabee.ovh/groups/a%7Cb",
            "https://link.exlibris.lunabee.ovh/groups/a%3Fslug=b",
            "https://link.exlibris.lunabee.ovh/groups/le%20club",
            "https://link.exlibris.lunabee.ovh/groups/le-club.",
            "https://link.exlibris.lunabee.ovh/groups/le-club/members",
            "https://link.exlibris.lunabee.ovh/groups",
            "http://link.exlibris.lunabee.ovh/groups/le-club-de-lecture",
            "https://inventaire.io/groups/le-club-de-lecture"
        ]

        for string in urls {
            let url: URL = try #require(URL(string: string))
            #expect(DeepLink(url: url) == nil, "\(string)")
        }
    }

    @Test
    func `a list link carries its id and the element it names if any`() throws {
        let list: URL = try #require(URL(string: "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)"))
        let element: URL = try #require(
            URL(string: "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)/element/\(Self.elementId)")
        )

        #expect(DeepLink(url: list) == .list(id: Self.listId, elementId: nil))
        #expect(DeepLink(url: element) == .list(id: Self.listId, elementId: Self.elementId))
    }

    @Test
    func `a list id or an element id that is not a couchdb id is not a link`() throws {
        let urls: [String] = [
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)%7C\(Self.listId)",
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)/element/a%26b",
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)/element/\(Self.elementId)%26ids=x",
            "https://link.exlibris.lunabee.ovh/lists/88B00676D608D9D53C5974FD9BC1009A",
            "https://link.exlibris.lunabee.ovh/lists/88b00676d608d9d53c5974fd9bc1009",
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)0",
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)/element",
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)/elements/\(Self.elementId)",
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)/element/\(Self.elementId)/edit",
            "https://link.exlibris.lunabee.ovh/lists/\(Self.listId)/\(Self.elementId)",
            "https://link.exlibris.lunabee.ovh/lists",
            "https://link.exlibris.lunabee.ovh/list/\(Self.listId)",
            "http://link.exlibris.lunabee.ovh/lists/\(Self.listId)",
            "https://inventaire.io/lists/\(Self.listId)"
        ]

        for string in urls {
            let url: URL = try #require(URL(string: string))
            #expect(DeepLink(url: url) == nil, "\(string)")
        }
    }

    @Test
    func `a copy link and an étagère link carry their id`() throws {
        let item: URL = try #require(URL(string: "https://link.exlibris.lunabee.ovh/items/\(Self.itemId)"))
        let shelf: URL = try #require(URL(string: "https://link.exlibris.lunabee.ovh/shelves/\(Self.shelfId)"))

        #expect(DeepLink(url: item) == .item(id: Self.itemId))
        #expect(DeepLink(url: shelf) == .shelf(id: Self.shelfId))
    }

    @Test
    func `a copy id or an étagère id that is not a couchdb id is not a link`() throws {
        let urls: [String] = [
            "https://link.exlibris.lunabee.ovh/items/\(Self.itemId)%7C\(Self.itemId)",
            "https://link.exlibris.lunabee.ovh/items/\(Self.itemId)%26ids=\(Self.itemId)",
            "https://link.exlibris.lunabee.ovh/shelves/\(Self.shelfId)%7C\(Self.shelfId)",
            "https://link.exlibris.lunabee.ovh/shelves/\(Self.shelfId)%26with-items-ids=true",
            "https://link.exlibris.lunabee.ovh/items/D3E1127CFC074506949A3C9396E4BCCB",
            "https://link.exlibris.lunabee.ovh/items/\(Self.itemId)0",
            "https://link.exlibris.lunabee.ovh/shelves/2b8c1752cc1195dafc3a8910f80822d",
            "https://link.exlibris.lunabee.ovh/items/\(Self.itemId)/edit",
            "https://link.exlibris.lunabee.ovh/shelves/\(Self.shelfId)/items",
            "https://link.exlibris.lunabee.ovh/items",
            "https://link.exlibris.lunabee.ovh/item/\(Self.itemId)",
            "https://link.exlibris.lunabee.ovh/shelf/\(Self.shelfId)",
            "http://link.exlibris.lunabee.ovh/items/\(Self.itemId)",
            "https://inventaire.io/shelves/\(Self.shelfId)"
        ]

        for string in urls {
            let url: URL = try #require(URL(string: string))
            #expect(DeepLink(url: url) == nil, "\(string)")
        }
    }

    @Test
    func `a link falls back to the same page on inventaire.io`() {
        #expect(DeepLink.entity(uri: "wd:Q535").webURL?.absoluteString == "https://inventaire.io/entity/wd:Q535")
        #expect(DeepLink.user(username: "maxlath").webURL?.absoluteString == "https://inventaire.io/users/maxlath")
        #expect(
            DeepLink.group(slug: "le-club-de-lecture").webURL?.absoluteString
                == "https://inventaire.io/groups/le-club-de-lecture"
        )
        #expect(
            DeepLink.list(id: Self.listId, elementId: nil).webURL?.absoluteString
                == "https://inventaire.io/lists/\(Self.listId)"
        )
        #expect(
            DeepLink.list(id: Self.listId, elementId: Self.elementId).webURL?.absoluteString
                == "https://inventaire.io/lists/\(Self.listId)/element/\(Self.elementId)"
        )
        #expect(DeepLink.item(id: Self.itemId).webURL?.absoluteString == "https://inventaire.io/items/\(Self.itemId)")
        #expect(DeepLink.shelf(id: Self.shelfId).webURL?.absoluteString == "https://inventaire.io/shelves/\(Self.shelfId)")
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
