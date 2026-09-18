//
//  ResolveRequestBuilderTests.swift
//  ReCIT_iOSTests
//
//  The body that creates a book on inventaire.io, asserted where it is decided rather than
//  where it is sent. Pure and network-free: the builder is the module that carries the rules
//  a duplicate would come from, so it is the module worth pinning down.
//
//  See PRD 0015.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("ResolveRequestBuilder")
struct ResolveRequestBuilderTests {

    private func draft(
        isbn: String = "978-2-38019-274-1",
        title: String = "La Main gauche de la nuit",
        author: String = "Ursula K. Le Guin",
        authorUri: String? = nil,
        workUri: String? = nil,
        language: EditionLanguage? = nil
    ) -> NewBookDraft {
        .init(
            isbn: isbn,
            title: title,
            authorName: author,
            authorUri: authorUri,
            workUri: workUri,
            language: language
        )
    }

    private let french: EditionLanguage = .init(uri: "wd:Q150", code: "fr")

    @Test("The ISBN travels without its separators")
    func isbnIsNormalized() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        #expect(request.entries.first?.edition.claims?["wdt:P212"] == ["9782380192741"])
    }

    @Test("The edition carries the title that is printed on this cover")
    func editionCarriesItsOwnTitle() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        #expect(request.entries.first?.edition.claims?["wdt:P1476"] == ["La Main gauche de la nuit"])
    }

    @Test("Whitespace typed around a title or a name does not reach the server")
    func fieldsAreTrimmed() throws {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(title: "  Les Dépossédés \n", author: " Ursula K. Le Guin "),
            create: true,
            language: "fr"
        )

        let entry: EntityResolveRequest.Entry = try #require(request.entries.first)
        #expect(entry.edition.claims?["wdt:P1476"] == ["Les Dépossédés"])
        #expect(entry.works?.first?.labels == ["fr": "Les Dépossédés"])
        #expect(entry.authors?.first?.labels == ["fr": "Ursula K. Le Guin"])
    }

    @Test("A book being created is described, and names no entity")
    func newEntitiesAreDescribedNotNamed() throws {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        let entry: EntityResolveRequest.Entry = try #require(request.entries.first)
        #expect(entry.authors?.first?.uri == nil)
        #expect(entry.works?.first?.uri == nil)
        #expect(entry.edition.uri == nil)
    }

    /// Half an entry is worse than none: a work created without its edition leaves an orphan
    /// on a public website that only a human can clean up.
    @Test("The creating request asks for creation, enrichment and strictness")
    func creatingRequestCarriesItsFlags() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        #expect(request.create == true)
        #expect(request.enrich == true)
        #expect(request.strict == true)
    }

    @Test("The reconnaissance request writes nothing")
    func dryRunCreatesNothing() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: false,
            language: "fr"
        )

        #expect(request.create == false)
    }

    @Test("Labels are written in the language they are asked for")
    func labelsFollowTheLanguage() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "en"
        )

        #expect(request.entries.first?.works?.first?.labels?.keys.first == "en")
    }

    // MARK: - An author who already exists

    /// Sending a description where a uri was available is how a database of this kind fills
    /// with twins, and merging two authors is not something a phone can undo.
    @Test("An author who was chosen is named by uri, and not described")
    func chosenAuthorIsNamed() throws {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(authorUri: "wd:Q182589"),
            create: true,
            language: "fr"
        )

        let author: EntityResolveRequest.Seed = try #require(request.entries.first?.authors?.first)
        #expect(author.uri == "wd:Q182589")
        #expect(author.labels == nil)
    }

    @Test("An author being created is described, and names nothing")
    func newAuthorIsDescribed() throws {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        let author: EntityResolveRequest.Seed = try #require(request.entries.first?.authors?.first)
        #expect(author.uri == nil)
        #expect(author.labels == ["fr": "Ursula K. Le Guin"])
    }

    // MARK: - A work that already exists

    /// Describing the work again would offer the server a second one to create, next to the
    /// one it has just recognised.
    @Test("A recognised work is claimed by the edition, and seeded nowhere")
    func recognisedWorkBecomesAClaim() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(workUri: "wd:Q1130619"),
            create: true,
            language: "fr"
        )

        #expect(request.entries.first?.edition.claims?["wdt:P629"] == ["wd:Q1130619"])
        #expect(request.entries.first?.works == nil)
    }

    @Test("Without a recognised work, one is described and nothing is claimed")
    func unrecognisedWorkIsSeeded() throws {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        let entry: EntityResolveRequest.Entry = try #require(request.entries.first)
        #expect(entry.edition.claims?["wdt:P629"] == nil)
        #expect(entry.works?.first?.labels == ["fr": "La Main gauche de la nuit"])
    }

    /// The title typed is the one printed on this cover; the work it belongs to may be called
    /// something else, and that is exactly what the recognition screen is about.
    @Test("Attaching to a known work does not change the edition's own title")
    func editionKeepsItsTitleWhenAttached() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(title: "La Main gauche de la nuit", workUri: "wd:Q1130619"),
            create: true,
            language: "fr"
        )

        #expect(request.entries.first?.edition.claims?["wdt:P1476"] == ["La Main gauche de la nuit"])
    }

    // MARK: - The language the ISBN answered

    @Test("The language the ISBN gave becomes a claim on the edition")
    func languageBecomesAClaim() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(language: french),
            create: true,
            language: "en"
        )

        #expect(request.entries.first?.edition.claims?["wdt:P407"] == ["wd:Q150"])
    }

    /// A wrong language on a public edition reads, ever after, as something somebody checked.
    @Test("No language means no claim, not a guessed one")
    func absentLanguageIsOmitted() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        #expect(request.entries.first?.edition.claims?["wdt:P407"] == nil)
    }

    /// The ISBN knows the book's language; the phone only knows the reader's.
    @Test("Labels follow the book's language rather than the phone's")
    func labelsFollowTheBookNotThePhone() {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(language: french),
            create: true,
            language: "en"
        )

        #expect(request.entries.first?.works?.first?.labels?.keys.first == "fr")
    }

    /// Optional fields are omitted rather than sent null: the server reads a present key as an
    /// intention, and `"uri": null` is not one.
    @Test("An absent uri is absent from the encoded body, not null")
    func encodingOmitsAbsentFields() throws {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(
            for: draft(),
            create: true,
            language: "fr"
        )

        let body: String = String(decoding: try JSONEncoder().encode(request), as: UTF8.self)

        #expect(body.contains("\"uri\"") == false)
        #expect(body.contains("null") == false)
    }
}
