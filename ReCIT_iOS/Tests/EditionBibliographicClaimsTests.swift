//
//  EditionBibliographicClaimsTests.swift
//  ReCIT_iOSTests
//
//  What an edition's row says under its title — ISBN, publisher, collection, year — read off its
//  claims, compared in one ISBN form, and never emptied by a sparse answer. PRD 0028.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Edition bibliographic claims", .serialized)
struct EditionBibliographicClaimsTests {

    // MARK: - Fixtures

    private func dto(_ uri: String = "inv:E1", invId: String? = "E1", claims: String) throws -> EntityResultDTO {
        let invIdField: String = invId.map { #","invId":"\#($0)""# } ?? ""
        let json: String = #"{"uri":"\#(uri)"\#(invIdField),"type":"edition","labels":{},"claims":\#(claims)}"#
        return try JSONDecoder().decode(EntityResultDTO.self, from: Data(json.utf8))
    }

    private let fullClaims: String = #"""
    {"wdt:P1476":["Le Comte de Monte-Cristo"],"wdt:P212":["978-2-07-036822-8"],"wdt:P123":["wd:Q3283253"],
     "wdt:P195":["wd:Q3070346"],"wdt:P577":["1998-03-01"],"wdt:P1104":[542],"wdt:P1889":["inv:E2"]}
    """#

    // MARK: - Reading the claims

    @Test("The ISBN-13 is read as written, the ISBN-10 only when there is no ISBN-13")
    func isbnPrefersThirteen() throws {
        let both: EditionBibliographicClaims = .init(claims: try dto(claims: #"{"wdt:P212":["978-2-07-036822-8"],"wdt:P957":["2-07-036822-X"]}"#).claims)
        let tenOnly: EditionBibliographicClaims = .init(claims: try dto(claims: #"{"wdt:P957":["2-07-036822-X"]}"#).claims)
        let none: EditionBibliographicClaims = .init(claims: try dto(claims: "{}").claims)

        #expect(both.isbn == "978-2-07-036822-8")
        #expect(tenOnly.isbn == "2-07-036822-X")
        #expect(none.isbn == nil)
    }

    @Test("Publisher, collection, date, pages and « different from » are read")
    func readsEveryClaim() throws {
        let claims: EditionBibliographicClaims = .init(claims: try dto(claims: fullClaims).claims)

        #expect(claims.publisherUri == "wd:Q3283253")
        #expect(claims.collectionUri == "wd:Q3070346")
        #expect(claims.publicationDate == "1998-03-01")
        #expect(claims.numberOfPages == 542)
        #expect(claims.differentFromUris == ["inv:E2"])
    }

    @Test("A year is the date's first component, whatever its precision")
    func yearOfADate() {
        #expect(EditionBibliographicClaims.year(of: "1995") == "1995")
        #expect(EditionBibliographicClaims.year(of: "1995-03") == "1995")
        #expect(EditionBibliographicClaims.year(of: "1995-03-01") == "1995")
        #expect(EditionBibliographicClaims.year(of: nil) == nil)
        #expect(EditionBibliographicClaims.year(of: "") == nil)
    }

    // MARK: - ISBN normalization

    @Test("Hyphens and spaces do not count")
    func normalizationStripsSeparators() {
        #expect(IsbnNormalization.normalized("978-2-07-036822-8") == "9782070368228")
        #expect(IsbnNormalization.normalized("978 2 07 036822 8") == "9782070368228")
    }

    @Test("An ISBN-10 is the ISBN-13 it stands for")
    func normalizationConvertsTen() {
        #expect(IsbnNormalization.normalized("2-07-036822-X") == "9782070368228")
        #expect(IsbnNormalization.normalized("2-07-036822-x") == "9782070368228")
        #expect(IsbnNormalization.normalized("0198534531") == "9780198534532")
    }

    @Test("A string of neither shape is no ISBN")
    func normalizationRejectsTheRest() {
        #expect(IsbnNormalization.normalized(nil) == nil)
        #expect(IsbnNormalization.normalized("") == nil)
        #expect(IsbnNormalization.normalized("12345") == nil)
        #expect(IsbnNormalization.normalized("97820703682X8") == nil)
    }

    // MARK: - Upsert

    @Test("Upserting an edition fills its ISBN, publisher, collection, date, pages and inv uri")
    func upsertFills() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = try context.upsertEdition(try dto(claims: fullClaims), works: [], apiService: MockAPIService())

        #expect(edition.isbn == "978-2-07-036822-8")
        #expect(edition.publisherUri == "wd:Q3283253")
        #expect(edition.collectionUri == "wd:Q3070346")
        #expect(edition.publicationDate == "1998-03-01")
        #expect(edition.publicationYear == "1998")
        #expect(edition.numberOfPages == 542)
        #expect(edition.invUri == "inv:E1")
        #expect(edition.differentFromUris == ["inv:E2"])
    }

    @Test("A sparse answer empties none of them")
    func sparseAnswerKeepsEverything() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = try context.upsertEdition(try dto(claims: fullClaims), works: [], apiService: MockAPIService())
        edition.publisherName = "Gallimard"
        edition.collectionName = "Folio classique"
        try context.save()

        let again: Edition = try context.upsertEdition(try dto(invId: nil, claims: "{}"), works: [], apiService: MockAPIService())
        try context.save()

        #expect(again === edition)
        #expect(edition.isbn == "978-2-07-036822-8")
        #expect(edition.publisherName == "Gallimard")
        #expect(edition.collectionName == "Folio classique")
        #expect(edition.publicationDate == "1998-03-01")
        #expect(edition.numberOfPages == 542)
        #expect(edition.invUri == "inv:E1")
        #expect(edition.differentFromUris == ["inv:E2"])
    }

    @Test("A publisher that changes forgets the old one's name")
    func newPublisherDropsOldName() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = try context.upsertEdition(try dto(claims: fullClaims), works: [], apiService: MockAPIService())
        edition.publisherName = "Gallimard"

        try context.upsertEdition(try dto(claims: #"{"wdt:P123":["wd:Q0"]}"#), works: [], apiService: MockAPIService())

        #expect(edition.publisherUri == "wd:Q0")
        #expect(edition.publisherName == nil)
    }

    @Test("A Wikidata edition has no inv uri to merge from")
    func wikidataHasNoInvUri() throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = try context.upsertEdition(try dto("wd:Q1", invId: "abc", claims: "{}"), works: [], apiService: MockAPIService())

        #expect(edition.invUri == nil)
    }

    // MARK: - Revalidating a work's editions

    @Test("« Éditions » refetches every edition, names its publisher, and detaches the one no longer listed")
    func refreshWorkEditions() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let work: Work = .init(uri: "wd:W1", lastrevid: 1, title: "Le Comte de Monte-Cristo")
        let kept: Edition = .init(uri: "inv:E1", title: "Tome 1", lang: "fr", authorNames: [])
        let merged: Edition = .init(uri: "inv:E2", title: "Tome 1 bis", lang: "fr", authorNames: [])
        context.insert(work)
        context.insert(kept)
        context.insert(merged)
        kept.mergeWorks([work])
        merged.mergeWorks([work])
        try context.save()

        let api: MockAPIService = .init()
        api.stub("reverse-claims", json: #"{"uris":["inv:E1"]}"#)
        api.stub("uris=inv:E1&", json: #"""
        {"entities":{"inv:E1":{"uri":"inv:E1","invId":"E1","type":"edition","labels":{},
         "claims":{"wdt:P629":["wd:W1"],"wdt:P212":["978-2-07-036822-8"],"wdt:P123":["wd:Q3283253"]}}}}
        """#)
        api.stub("uris=wd:Q3283253&", json: #"{"entities":{"wd:Q3283253":{"uri":"wd:Q3283253","type":"publisher","labels":{"fr":"Gallimard"}}}}"#)

        try await EntityModel(apiService: api).refreshWorkEditions(modelContext: context, work: work)

        #expect(kept.isbn == "978-2-07-036822-8")
        #expect(kept.publisherName == "Gallimard")
        #expect(work.editions.map(\.uri) == ["inv:E1"])
        #expect(try context.fetch(FetchDescriptor<Edition>()).count == 2)
    }

    // MARK: - Row

    @Test("The row's second line joins what is known of publisher, collection and year")
    func rowDetails() {
        let edition: Edition = .init(uri: "inv:E1", title: "Le Comte de Monte-Cristo", lang: "fr", authorNames: [])
        #expect(EditionCell.details(of: edition) == nil)

        edition.publisherName = "Gallimard"
        edition.publicationDate = "1998"
        #expect(EditionCell.details(of: edition) == "Gallimard · 1998")

        edition.collectionName = "Folio classique"
        #expect(EditionCell.details(of: edition) == "Gallimard · Folio classique · 1998")
    }

    @Test("Editions are listed oldest first, undated last, then by title")
    func listOrder() {
        func edition(_ uri: String, _ title: String, _ date: String?) -> Edition {
            let edition: Edition = .init(uri: uri, title: title, lang: nil, authorNames: [])
            edition.publicationDate = date
            return edition
        }
        let editions: [Edition] = [
            edition("inv:4", "Zola", nil),
            edition("inv:3", "B", "2020"),
            edition("inv:2", "B", "1995"),
            edition("inv:1", "A", "1995")
        ]

        #expect(editions.sorted(by: WorkEditionPicker.listOrder).map(\.uri) == ["inv:1", "inv:2", "inv:3", "inv:4"])
    }
}
