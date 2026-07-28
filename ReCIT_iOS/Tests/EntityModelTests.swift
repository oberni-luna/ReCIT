//
//  EntityModelTests.swift
//  ReCIT_iOSTests
//
//  Covers the entity sync layer: cache-first reads, background revalidation
//  (upsert in place), and the defensive DTO merge that prevents a sparse
//  server response from wiping data already cached.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EntityModel sync", .serialized)
struct EntityModelTests {

    // MARK: - JSON fixtures

    /// A single entity wrapped in the `by-uris` envelope. `claims` is always
    /// present (the DTO requires it) and defaults to empty so no secondary
    /// author/work fetch is triggered.
    private func entityEnvelope(_ body: String) -> String {
        #"{"entities":{"x":\#(body)}}"#
    }

    private func authorJSON(
        uri: String,
        label: String,
        image: String?,
        description: String?
    ) -> String {
        let imageField: String = image.map { #""image":{"url":"\#($0)","file":null,"credit":null},"# } ?? ""
        let descField: String = description.map { #""descriptions":{"fr":"\#($0)"},"# } ?? ""
        return entityEnvelope("""
        {"uri":"\(uri)","lastrevid":10,"type":"human","labels":{"fr":"\(label)"},\(descField)\(imageField)"claims":{"wdt:P569":["1802-02-26"]}}
        """)
    }

    private func workJSON(
        uri: String,
        label: String,
        image: String?,
        description: String?
    ) -> String {
        let imageField: String = image.map { #""image":{"url":"\#($0)","file":null,"credit":null},"# } ?? ""
        let descField: String = description.map { #""descriptions":{"fr":"\#($0)"},"# } ?? ""
        return entityEnvelope("""
        {"uri":"\(uri)","lastrevid":5,"type":"work","originalLang":"fr","labels":{"fr":"\(label)"},\(descField)\(imageField)"claims":{}}
        """)
    }

    private func editionJSON(
        uri: String,
        title: String,
        subtitle: String?
    ) -> String {
        let descField: String = subtitle.map { #""descriptions":{"fromclaims":"\#($0)"},"# } ?? ""
        return entityEnvelope("""
        {"uri":"\(uri)","type":"edition","originalLang":"fr","labels":{"fromclaims":"\(title)"},\(descField)"image":{"url":"/img/ed.jpg","file":null,"credit":null},"claims":{}}
        """)
    }

    private let emptyEntities: String = #"{"entities":{}}"#

    // MARK: - Cache-first reads

    @Test("localWork returns nil when nothing is cached, then the cached value")
    func localWorkReadsCache() throws {
        let context: ModelContext = try TestStore.makeContext()
        let model: EntityModel = .init(apiService: MockAPIService())

        #expect(model.localWork(modelContext: context, uri: "wd:Q1") == nil)

        let work: Work = .init(uri: "wd:Q1", lastrevid: 0, title: "Cached")
        context.insert(work)
        try context.save()

        #expect(model.localWork(modelContext: context, uri: "wd:Q1")?.title == "Cached")
    }

    // MARK: - Insert on first fetch

    @Test("refreshWork inserts a new work from the remote payload")
    func refreshWorkInsertsNew() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: workJSON(uri: "wd:Q235", label: "Les Misérables", image: "/img/mis.jpg", description: "roman"))
        let model: EntityModel = .init(apiService: mock)

        let work: Work = try #require(try await model.refreshWork(modelContext: context, uri: "wd:Q235"))

        #expect(work.title == "Les Misérables")
        #expect(work.subtitle == "roman")
        #expect(work.image?.contains("mis.jpg") == true)

        let stored: [Work] = try context.fetch(FetchDescriptor<Work>())
        #expect(stored.count == 1)
    }

    @Test("refreshAuthor inserts a new author and maps its metadata")
    func refreshAuthorInsertsNew() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: authorJSON(uri: "wd:Q535", label: "Victor Hugo", image: "/img/hugo.jpg", description: "écrivain"))
        let model: EntityModel = .init(apiService: mock)

        let author: Author = try #require(try await model.refreshAuthor(modelContext: context, uri: "wd:Q535"))

        #expect(author.name == "Victor Hugo")
        #expect(author.subtitle == "écrivain")
        #expect(author.image?.contains("hugo.jpg") == true)
        #expect(author.dateOfBirth != nil)
    }

    @Test("refreshEdition inserts a new edition from the remote payload")
    func refreshEditionInsertsNew() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: editionJSON(uri: "inv:ed1", title: "Les Misérables — Poche", subtitle: "éd. 1998"))
        let model: EntityModel = .init(apiService: mock)

        let edition: Edition = try #require(try await model.refreshEdition(modelContext: context, uri: "inv:ed1"))

        #expect(edition.title == "Les Misérables — Poche")
        #expect(edition.subtitle == "éd. 1998")
        #expect(edition.lang == "fr")
    }

    // MARK: - Upsert in place (the sparse-forever bug fix)

    @Test("refreshWork updates the cached work in place instead of duplicating it")
    func refreshWorkUpdatesInPlace() async throws {
        let context: ModelContext = try TestStore.makeContext()
        // A sparse first fetch left this work almost empty.
        let sparse: Work = .init(uri: "wd:Q235", lastrevid: 0, title: "Unknown")
        context.insert(sparse)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: workJSON(uri: "wd:Q235", label: "Les Misérables", image: "/img/mis.jpg", description: "roman"))
        let model: EntityModel = .init(apiService: mock)

        let work: Work = try #require(try await model.refreshWork(modelContext: context, uri: "wd:Q235"))

        #expect(work.title == "Les Misérables")
        #expect(work.image?.contains("mis.jpg") == true)

        // No duplicate inserted — the unique entity was updated in place.
        let stored: [Work] = try context.fetch(FetchDescriptor<Work>())
        #expect(stored.count == 1)
        #expect(stored.first?.title == "Les Misérables")
    }

    // MARK: - Defensive merge

    @Test("A sparse remote payload never wipes fields already cached")
    func sparseRemoteKeepsExistingData() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let populated: Author = .init(
            uri: "wd:Q535",
            lastrevid: 1,
            name: "Victor Hugo",
            image: "https://cached.example/hugo.jpg",
            subtitle: "écrivain français"
        )
        context.insert(populated)
        try context.save()

        // Remote responds with only a label — no image, no description.
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: authorJSON(uri: "wd:Q535", label: "Victor Hugo (maj)", image: nil, description: nil))
        let model: EntityModel = .init(apiService: mock)

        let author: Author = try #require(try await model.refreshAuthor(modelContext: context, uri: "wd:Q535"))

        #expect(author.name == "Victor Hugo (maj)")           // updated
        #expect(author.image == "https://cached.example/hugo.jpg") // preserved
        #expect(author.subtitle == "écrivain français")           // preserved
    }

    // MARK: - Remote yields nothing

    @Test("refreshWork returns the cached value when the remote yields no entity")
    func refreshWorkKeepsCacheWhenRemoteEmpty() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let cached: Work = .init(uri: "wd:Q1", lastrevid: 0, title: "Cached")
        context.insert(cached)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: emptyEntities)
        let model: EntityModel = .init(apiService: mock)

        let work: Work = try #require(try await model.refreshWork(modelContext: context, uri: "wd:Q1"))
        #expect(work.title == "Cached")
    }

    @Test("refreshWork returns nil when there is neither a cache nor a remote entity")
    func refreshWorkNilWhenNothing() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/entities/by-uris", json: emptyEntities)
        let model: EntityModel = .init(apiService: mock)

        let work: Work? = try await model.refreshWork(modelContext: context, uri: "wd:Q404")
        #expect(work == nil)
    }

    // MARK: - Get-or-fetch cache hit

    @Test("getOrFetchWorks returns cached works without hitting the network")
    func getOrFetchWorksCacheHit() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let cached: Work = .init(uri: "wd:Q1", lastrevid: 0, title: "Cached")
        context.insert(cached)
        try context.save()

        let mock: MockAPIService = .init()
        let model: EntityModel = .init(apiService: mock)

        let works: [Work] = try #require(try await model.getOrFetchWorks(modelContext: context, uris: ["wd:Q1"]))
        #expect(works.count == 1)
        #expect(works.first?.title == "Cached")
        #expect(mock.recordedRequests.isEmpty)
    }
}
