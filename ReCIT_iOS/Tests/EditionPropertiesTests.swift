//
//  EditionPropertiesTests.swift
//  ReCIT_iOSTests
//
//  The catalogue of an edition's properties and the values the form holds for them: what is
//  read from `by-uris`, what a typed identifier is turned into, and which claims a change comes
//  to — one update naming the value it replaces for a single value, one per value added or taken
//  away for several.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EditionProperties")
struct EditionPropertiesTests {

    private let editionUri: String = "inv:edition"

    private var gallimard: EditionEntityValue {
        .init(uri: "wd:Q336718", label: "Gallimard")
    }

    // MARK: - The catalogue

    @Test("Every property of the catalogue is named once")
    func catalogueHasNoTwin() {
        let uris: [String] = EditionProperty.all.map(\.uri)
        #expect(Set(uris).count == uris.count)
        #expect(EditionProperty.databases.count == 22)
        #expect(EditionProperty.links.count == 10)
        #expect(EditionProperty.contributors.count == 6)
        #expect(EditionProperty.named("wdt:P212") == nil)
        #expect(EditionProperty.named("wdt:P1889") == nil)
    }

    @Test("An identifier is checked against the server's pattern, after its small rewrites")
    func identifiersAreValidated() {
        let bnf: EditionProperty = EditionProperty.named("wdt:P268")!
        #expect(bnf.literal(from: "cb123735831") == "123735831")
        #expect(bnf.literal(from: " 123735831 ") == "123735831")
        #expect(bnf.literal(from: "12373583") == nil)

        let openLibrary: EditionProperty = EditionProperty.named("wdt:P648")!
        #expect(openLibrary.literal(from: "OL61173905M") == "OL61173905M")
        // A work's identifier is not an edition's.
        #expect(openLibrary.literal(from: "OL36858W") == nil)

        let mastodon: EditionProperty = EditionProperty.named("wdt:P4033")!
        #expect(mastodon.literal(from: "@jz@mamot.fr") == "jz@mamot.fr")

        let doi: EditionProperty = EditionProperty.named("wdt:P356")!
        #expect(doi.literal(from: "10.1371/journal.pone.0029797") != nil)
    }

    @Test("Every example the server gives passes its own pattern")
    func examplesPass() {
        for property in EditionProperty.databases + EditionProperty.links {
            guard case .identifier(_, let example) = property.kind else { continue }
            #expect(property.literal(from: example) != nil, "\(property.uri) refuses \(example)")
        }
    }

    @Test("A count is a positive number; a link is an http address")
    func countsAndLinks() {
        #expect(EditionProperty.numberOfPages.literal(from: "256") == .integer(256))
        #expect(EditionProperty.numberOfPages.literal(from: "0") == nil)
        #expect(EditionProperty.numberOfPages.literal(from: "") == nil)

        let website: EditionProperty = EditionProperty.named("wdt:P856")!
        #expect(website.literal(from: "https://www.gallimard.fr") == "https://www.gallimard.fr")
        #expect(website.literal(from: "gallimard.fr") == nil)
        #expect(website.literal(from: "ftp://gallimard.fr") == nil)
    }

    // MARK: - Reading

    @Test("Values are read from the claims, entities named, counts kept as numbers")
    func readsClaims() {
        let properties: EditionProperties = .init(
            claims: [
                "wdt:P123": [.string("wd:Q336718")],
                "wdt:P407": [.string("wd:Q150")],
                "wdt:P1104": [.number(256)],
                "wdt:P577": [.string("2023-03")],
                "wdt:P268": [.string("123735831")],
                "wdt:P212": [.string("978-2-07-036822-8")]
            ],
            labels: ["wd:Q336718": "Gallimard"]
        )

        #expect(properties.entities(of: .publisher).map(\.label) == ["Gallimard"])
        // Not named by the server: the uri stands in.
        #expect(properties.entities(of: .language).map(\.label) == ["wd:Q150"])
        #expect(properties.literal(of: .numberOfPages) == .integer(256))
        #expect(properties.literal(of: .publicationDate) == "2023-03")
        #expect(properties.claims["wdt:P268"] == ["123735831"])
        // The ISBN is not the catalogue's.
        #expect(properties.claims["wdt:P212"] == nil)
        #expect(properties.entityUris == ["wd:Q336718", "wd:Q150"])
    }

    // MARK: - What a change comes to

    @Test("A single value replaced names the one it replaces")
    func singleValueReplaced() {
        var original: EditionProperties = .init()
        original.setLiteral(.integer(192), for: .numberOfPages)
        var changed: EditionProperties = original
        changed.setLiteral(.integer(256), for: .numberOfPages)

        #expect(changed.updates(since: original, on: editionUri) == [
            .init(uri: editionUri, property: "wdt:P1104", oldValue: .integer(192), newValue: .integer(256))
        ])

        changed.setLiteral(nil, for: .numberOfPages)
        #expect(changed.updates(since: original, on: editionUri) == [
            .init(uri: editionUri, property: "wdt:P1104", oldValue: .integer(192), newValue: nil)
        ])
    }

    @Test("Several values send one update per value added or taken away")
    func multipleValues() {
        var original: EditionProperties = .init()
        original.add(gallimard, to: .publisher)
        original.addLiteral("123735831", to: EditionProperty.named("wdt:P268")!)

        var changed: EditionProperties = original
        changed.remove(atOffsets: [0], from: .publisher)
        changed.add(.init(uri: "wd:Q3053361", label: "Folio"), to: .collection)

        #expect(changed.updates(since: original, on: editionUri) == [
            .init(uri: editionUri, property: "wdt:P123", oldValue: "wd:Q336718", newValue: nil),
            .init(uri: editionUri, property: "wdt:P195", oldValue: nil, newValue: "wd:Q3053361")
        ])
    }

    @Test("The same entity or literal is not added twice")
    func noTwins() {
        var properties: EditionProperties = .init()
        properties.add(gallimard, to: .publisher)
        properties.add(.init(uri: "wd:Q336718", label: "Éditions Gallimard"), to: .publisher)
        properties.add(.init(label: "Le Sous-Bois"), to: .publisher)
        properties.add(.init(label: "le sous-bois "), to: .publisher)
        #expect(properties.entities(of: .publisher).count == 2)

        let bnf: EditionProperty = EditionProperty.named("wdt:P268")!
        properties.addLiteral("123735831", to: bnf)
        properties.addLiteral("123735831", to: bnf)
        #expect(properties.values(of: bnf).count == 1)
    }

    @Test("An entity to create is sent only once it exists, and collections are created last")
    func pendingEntities() {
        let original: EditionProperties = .init()
        var changed: EditionProperties = original
        changed.add(.init(label: "Collection du Sous-Bois"), to: .collection)
        changed.add(.init(label: "Le Sous-Bois"), to: .publisher)
        changed.add(.init(label: "Irina Petrova"), to: EditionProperty.contributors[0])

        #expect(changed.updates(since: original, on: editionUri).isEmpty)
        #expect(changed.differs(from: original))
        #expect(changed.pendingEntities.map(\.property.uri) == ["wdt:P123", "wdt:P655", "wdt:P195"])
        #expect(changed.publisherUri == nil)

        let publisher: EditionEntityValue = changed.pendingEntities[0].entity
        changed.entityCreated(id: publisher.id, uri: "inv:publisher")

        #expect(changed.publisherUri == "inv:publisher")
        #expect(changed.updates(since: original, on: editionUri) == [
            .init(uri: editionUri, property: "wdt:P123", oldValue: nil, newValue: "inv:publisher")
        ])
    }

    @Test("A landed update moves into the original, with the name the form had")
    func landedUpdate() {
        var original: EditionProperties = .init()
        var changed: EditionProperties = original
        changed.add(gallimard, to: .publisher)

        let update: EditionClaimUpdate = changed.updates(since: original, on: editionUri)[0]
        original.apply(update, from: changed)

        #expect(original.entities(of: .publisher).map(\.label) == ["Gallimard"])
        #expect(changed.updates(since: original, on: editionUri).isEmpty)
        #expect(changed.differs(from: original) == false)
    }

    // MARK: - The date

    @Test("A date is a year, a month or a day, and nothing else")
    func publicationDates() {
        #expect(PublicationDate("2023")?.precision == .year)
        #expect(PublicationDate("2023-03")?.precision == .month)
        #expect(PublicationDate("2023-03-15")?.claim == "2023-03-15")
        #expect(PublicationDate("2023-13") == nil)
        #expect(PublicationDate("mars 2023") == nil)
        #expect(PublicationDate("2023-03-15-01") == nil)

        var date: PublicationDate = .init(year: 2023, month: 3, day: 15, precision: .day)
        date.precision = .month
        #expect(date.claim == "2023-03")
        date.precision = .year
        #expect(date.claim == "2023")
    }

    // MARK: - On the wire

    @Test("A count goes out as a JSON number, a uri as a string")
    func claimUpdateTypes() throws {
        let pages: EditionClaimUpdate = .init(uri: editionUri, property: "wdt:P1104", oldValue: nil, newValue: .integer(256))
        let json: String = String(decoding: try JSONEncoder().encode(pages), as: UTF8.self)
        #expect(json.contains(#""new-value":256"#))
        #expect(json.contains("old-value") == false)

        let decoded: EditionClaimUpdate = try JSONDecoder().decode(EditionClaimUpdate.self, from: Data(json.utf8))
        #expect(decoded == pages)
    }
}
