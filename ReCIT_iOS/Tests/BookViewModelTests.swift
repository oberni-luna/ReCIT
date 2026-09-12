//
//  BookViewModelTests.swift
//  ReCIT_iOSTests
//
//  Covers P1 of ADR 0002 (unified book screen): resolving a BookAnchor to an
//  Edition (cache-first + background revalidation) and the predicate that scopes
//  the current user's copies of an edition.
//
//  Move 3 added the third anchor — a search result naming a work, whose edition the screen picks
//  itself. Its cases are at the bottom. The one to read is `loadBestEditionOpensFromThePreference`:
//  a second tap must cost nothing and land on the same book, which is what `Work.preferredEditionUri`
//  is for.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("BookViewModel", .serialized)
struct BookViewModelTests {

    // MARK: - JSON fixtures

    /// A single edition wrapped in the `by-uris` envelope, with empty `claims`
    /// so no secondary work/author fetch is triggered.
    private func editionEnvelope(uri: String, title: String) -> String {
        #"""
        {"entities":{"x":{"uri":"\#(uri)","type":"edition","originalLang":"fr","labels":{"fromclaims":"\#(title)"},"image":{"url":"/img/ed.jpg","file":null,"credit":null},"claims":{}}}}
        """#
    }

    private let emptyEntities: String = #"{"entities":{}}"#

    private func loadedURI(_ state: BookViewModel.ViewState) -> String? {
        if case .loaded(let edition) = state { edition.uri } else { nil }
    }

    private func isNoResult(_ state: BookViewModel.ViewState) -> Bool {
        if case .noResult = state { true } else { false }
    }

    private func isError(_ state: BookViewModel.ViewState) -> Bool {
        if case .error = state { true } else { false }
    }

    // MARK: - Anchor resolution (pure)

    @Test("An edition anchor exposes its uri and a stable id")
    func editionAnchorResolves() {
        let anchor: BookAnchor = .edition(uri: "isbn:1")
        #expect(anchor.editionUri == "isbn:1")
        #expect(anchor.stableId == "edition:isbn:1")
    }

    @Test("An item anchor resolves to its edition's uri")
    func itemAnchorResolves() {
        let edition: Edition = Fixture.edition(uri: "isbn:1")
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: edition)
        let anchor: BookAnchor = .item(item)
        #expect(anchor.editionUri == "isbn:1")
        #expect(anchor.stableId == "item:i1")
    }

    @Test("An item anchor with no hydrated edition resolves to nil")
    func itemAnchorWithoutEditionResolvesNil() {
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        item.edition = nil
        let anchor: BookAnchor = .item(item)
        #expect(anchor.editionUri == nil)
    }

    @Test("A best-edition anchor has no uri to give, but a header to show")
    func bestEditionAnchorResolves() {
        let anchor: BookAnchor = .bestEditionOfWork(
            uri: "wd:Q190192",
            title: "Dune",
            imageUrl: "/img/dune.jpg"
        )

        // Deliberately nil: which edition it means is a network call, not a property.
        #expect(anchor.editionUri == nil)
        #expect(anchor.stableId == "work:wd:Q190192")
        #expect(anchor.placeholder?.title == "Dune")
        #expect(anchor.placeholder?.imageUrl == "/img/dune.jpg")
    }

    @Test("The anchors that resolve instantly have no placeholder to show")
    func instantAnchorsHaveNoPlaceholder() {
        #expect(BookAnchor.edition(uri: "isbn:1").placeholder == nil)
        #expect(BookAnchor.item(Fixture.inventoryItem(id: "i1", edition: Fixture.edition())).placeholder == nil)
    }

    @Test("Two anchors on the same work are one entry in the stack, whatever they were labelled")
    func stableIdIgnoresTheDisplayPayload() {
        let one: BookAnchor = .bestEditionOfWork(uri: "wd:Q1", title: "Dune", imageUrl: nil)
        let other: BookAnchor = .bestEditionOfWork(uri: "wd:Q1", title: "Dune (1965)", imageUrl: "/img/x")

        #expect(one == other)
    }

    // MARK: - load()

    @Test("load resolves an edition anchor to the loaded state")
    func loadEditionAnchor() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: editionEnvelope(uri: "inv:ed1", title: "Les Misérables — Poche"))
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .edition(uri: "inv:ed1"))
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(loadedURI(sut.viewState) == "inv:ed1")

        // Upsert in place: exactly one edition stored, no duplicate.
        let stored: [Edition] = try context.fetch(FetchDescriptor<Edition>())
        #expect(stored.count == 1)
    }

    @Test("load resolves an item anchor to its edition")
    func loadItemAnchor() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = Fixture.edition(uri: "inv:ed1", title: "Cached")
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: edition)
        context.insert(edition)
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: editionEnvelope(uri: "inv:ed1", title: "Les Misérables — Poche"))
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .item(item))
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(loadedURI(sut.viewState) == "inv:ed1")
    }

    @Test("load surfaces noResult when the item's edition is not hydrated")
    func loadItemAnchorWithoutEdition() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        item.edition = nil

        let mock: MockAPIService = .init()
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .item(item))
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(isNoResult(sut.viewState))
        #expect(mock.recordedRequests.isEmpty) // never hit the network
    }

    @Test("load surfaces noResult when neither cache nor remote has the edition")
    func loadNoResult() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: emptyEntities)
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .edition(uri: "inv:missing"))
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(isNoResult(sut.viewState))
    }

    @Test("load surfaces an error when there is no cache and the remote fails")
    func loadErrorWithoutCache() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", error: NetworkError.badStatus(code: 500, message: nil))
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .edition(uri: "inv:ed1"))
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(isError(sut.viewState))
    }

    @Test("load keeps showing the cached edition when the remote fails")
    func loadKeepsCacheOnRemoteFailure() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let cached: Edition = Fixture.edition(uri: "inv:ed1", title: "Cached")
        context.insert(cached)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", error: NetworkError.badStatus(code: 500, message: nil))
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .edition(uri: "inv:ed1"))
        await sut.load(entityModel: entityModel, modelContext: context)

        // Failure is swallowed: the stale-but-useful cached edition stays on screen.
        #expect(loadedURI(sut.viewState) == "inv:ed1")
    }

    // MARK: - ownedItemsPredicate

    @Test("ownedItemsPredicate matches only my copies of the given edition")
    func ownedItemsPredicateScopesByEditionAndOwner() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let ed1: Edition = Fixture.edition(uri: "isbn:1")
        let ed2: Edition = Fixture.edition(uri: "isbn:2")
        context.insert(ed1)
        context.insert(ed2)

        let mine: InventoryItem = Fixture.inventoryItem(id: "mine-ed1", ownerId: "me", edition: ed1)
        let other: InventoryItem = Fixture.inventoryItem(id: "other-ed1", ownerId: "you", edition: ed1)
        let mineOtherEdition: InventoryItem = Fixture.inventoryItem(id: "mine-ed2", ownerId: "me", edition: ed2)
        context.insert(mine)
        context.insert(other)
        context.insert(mineOtherEdition)
        try context.save()

        let predicate: Predicate<InventoryItem> = BookViewModel.ownedItemsPredicate(editionUri: "isbn:1", ownerId: "me")
        let fetched: [InventoryItem] = try context.fetch(FetchDescriptor<InventoryItem>(predicate: predicate))

        #expect(fetched.map(\._id) == ["mine-ed1"])
    }

    // MARK: - worksWithOtherEditions

    /// Builds an edition whose single work also exists in `siblingUris` other
    /// editions, all pre-cached so `getWorkEditions` needs no `by-uris` fetch.
    private func makeWorkWithEditions(
        context: ModelContext,
        workUri: String,
        editionUris: [String]
    ) -> Work {
        let work: Work = .init(uri: workUri, lastrevid: 0, title: "W")
        context.insert(work)
        for uri in editionUris {
            let edition: Edition = Fixture.edition(uri: uri)
            edition.works = [work]
            context.insert(edition)
        }
        return work
    }

    @Test("worksWithOtherEditions lists a work that has sibling editions")
    func otherEditionsPopulatedWhenSiblingsExist() async throws {
        let context: ModelContext = try TestStore.makeContext()
        _ = makeWorkWithEditions(context: context, workUri: "wd:W", editionUris: ["isbn:A", "isbn:B"])
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: emptyEntities) // refreshEdition keeps the cached edition
        mock.stub("/api/entities/reverse-claims", json: #"{"uris":["isbn:A","isbn:B"]}"#)
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .edition(uri: "isbn:A"))
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(sut.worksWithOtherEditions.map(\.uri) == ["wd:W"])
    }

    @Test("worksWithOtherEditions stays empty when the work has only this edition")
    func otherEditionsEmptyWhenNoSiblings() async throws {
        let context: ModelContext = try TestStore.makeContext()
        _ = makeWorkWithEditions(context: context, workUri: "wd:W", editionUris: ["isbn:A"])
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: emptyEntities)
        mock.stub("/api/entities/reverse-claims", json: #"{"uris":["isbn:A"]}"#)
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(anchor: .edition(uri: "isbn:A"))
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(sut.worksWithOtherEditions.isEmpty)
    }

    // MARK: - load() for a search result (ADR 0002, Move 3)

    /// A `by-uris` envelope keyed by the uri, as the server keys it — which is what the
    /// resolver looks candidates up by.
    private func candidateEnvelope(uri: String, lang: String, title: String) -> String {
        #"""
        {"entities":{"\#(uri)":{"uri":"\#(uri)","type":"edition","originalLang":"\#(lang)","labels":{"fromclaims":"\#(title)"},"image":{"url":"/img/ed.jpg","file":null,"credit":null},"claims":{"wdt:P1476":["\#(title)"]}}}}
        """#
    }

    @Test("A search result resolves to the French edition and the screen shows it")
    func loadBestEditionResolvesToAnEdition() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("reverse-claims", json: #"{"uris":["inv:fr"]}"#)
        mock.stub("/api/entities/by-uris", json: candidateEnvelope(uri: "inv:fr", lang: "fr", title: "Dune"))
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(
            anchor: .bestEditionOfWork(uri: "wd:Q190192", title: "Dune", imageUrl: nil)
        )
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(loadedURI(sut.viewState) == "inv:fr")
    }

    @Test("A work with no edition is noResult, not an error")
    func loadBestEditionWithNoEditionIsNoResult() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("reverse-claims", json: #"{"uris":[]}"#)
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(
            anchor: .bestEditionOfWork(uri: "wd:ghost", title: "Americanah", imageUrl: nil)
        )
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(isNoResult(sut.viewState))
        #expect(isError(sut.viewState) == false)
    }

    @Test("A call that failed is an error, not a book that does not exist")
    func loadBestEditionFailureIsAnError() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("reverse-claims", error: NetworkError.badStatus(code: 500, message: nil))
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(
            anchor: .bestEditionOfWork(uri: "wd:Q190192", title: "Dune", imageUrl: nil)
        )
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(isError(sut.viewState))
        #expect(isNoResult(sut.viewState) == false)
    }

    @Test("A second tap opens the same book, without waiting on the network")
    func loadBestEditionOpensFromThePreference() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let edition: Edition = Fixture.edition(uri: "inv:fr", title: "Dune")
        let work: Work = .init(uri: "wd:Q190192", lastrevid: 1, title: "Dune")
        work.preferredEditionUri = "inv:fr"
        context.insert(edition)
        context.insert(work)
        try context.save()

        let mock: MockAPIService = .init()
        // Every call fails. The screen must still open — which is the proof that the second tap
        // reads the preference rather than re-ranking. The background revalidation fails too,
        // silently, which is what it is supposed to do.
        mock.stub("reverse-claims", error: NetworkError.badStatus(code: 500, message: nil))
        mock.stub("/api/entities/by-uris", error: NetworkError.badStatus(code: 500, message: nil))
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(
            anchor: .bestEditionOfWork(uri: "wd:Q190192", title: "Dune", imageUrl: nil)
        )
        await sut.load(entityModel: entityModel, modelContext: context)

        #expect(loadedURI(sut.viewState) == "inv:fr")
    }

    @Test("An edition opened from the preference is still revalidated in the background")
    func preferredEditionIsRevalidated() async throws {
        // The bug this guards: the background pass used to call `refreshEdition` **only** when
        // the ranking landed on a different uri — almost never — so a row cached with a stale
        // title kept it on every visit. `wd:Q58464836`, cached as `Unknown` by the mapping that
        // preceded `EditionTitle`, is the copy a user actually met.
        let context: ModelContext = try TestStore.makeContext()
        let stale: Edition = Fixture.edition(uri: "wd:Q58464836", title: "Unknown")
        let work: Work = .init(uri: "wd:Q43361", lastrevid: 1, title: "Harry Potter")
        work.preferredEditionUri = "wd:Q58464836"
        context.insert(stale)
        context.insert(work)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("reverse-claims", json: #"{"uris":["wd:Q58464836"]}"#)
        mock.stub("/api/entities/by-uris", json: #"""
        {"entities":{"wd:Q58464836":{"uri":"wd:Q58464836","type":"edition","originalLang":"fr","labels":{"fr":"Harry Potter à l'école des sorciers"},"image":{"url":"/img/hp.jpg","file":null,"credit":null},"claims":{"wdt:P1476":["Harry Potter à l'école des sorciers"]}}}}
        """#)
        let entityModel: EntityModel = .init(apiService: mock)

        // The open itself returns the cached row, untouched — that is the point of the fast path.
        let opened: Edition? = try await entityModel.resolveBestEdition(
            modelContext: context,
            workUri: "wd:Q43361"
        )
        #expect(opened?.uri == "wd:Q58464836")

        // The background pass is what brings it up to date, in place (ADR 0001, invariant 2).
        await entityModel.performRevalidation(modelContext: context, workUri: "wd:Q43361")

        #expect(stale.title == "Harry Potter à l'école des sorciers")
        let editions: [Edition] = try context.fetch(FetchDescriptor<Edition>())
        #expect(editions.count == 1)   // upserted, not reinserted
    }

    @Test("A first tap writes the preference onto the work")
    func loadBestEditionRemembersItsChoice() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("reverse-claims", json: #"{"uris":["inv:fr"]}"#)
        // The edition claims the work, so `refreshEdition` materialises the `Work` — which is
        // what the preference is written onto, and why it is written there and not at tap time.
        // The work's own fetch is stubbed separately: matching is by substring in registration
        // order, so `uris=wd:…` has to come before the edition's broader match, or the work
        // would be decoded from the edition's payload.
        mock.stub("uris=wd:Q190192", json: #"""
        {"entities":{"wd:Q190192":{"uri":"wd:Q190192","type":"work","originalLang":"en","labels":{"fr":"Dune"},"claims":{}}}}
        """#)
        mock.stub("/api/entities/by-uris", json: #"""
        {"entities":{"inv:fr":{"uri":"inv:fr","type":"edition","originalLang":"fr","labels":{"fromclaims":"Dune"},"image":{"url":"/img/ed.jpg","file":null,"credit":null},"claims":{"wdt:P1476":["Dune"],"wdt:P629":["wd:Q190192"]}}}}
        """#)
        let entityModel: EntityModel = .init(apiService: mock)

        let sut: BookViewModel = .init(
            anchor: .bestEditionOfWork(uri: "wd:Q190192", title: "Dune", imageUrl: nil)
        )
        await sut.load(entityModel: entityModel, modelContext: context)

        let works: [Work] = try context.fetch(FetchDescriptor<Work>())
        #expect(works.first(where: { $0.uri == "wd:Q190192" })?.preferredEditionUri == "inv:fr")
    }
}
