//
//  BookViewModelTests.swift
//  ReCIT_iOSTests
//
//  Covers P1 of ADR 0002 (unified book screen): resolving a BookAnchor to an
//  Edition (cache-first + background revalidation) and the predicate that scopes
//  the current user's copies of an edition.
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
}
