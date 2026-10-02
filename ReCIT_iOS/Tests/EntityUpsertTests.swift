//
//  EntityUpsertTests.swift
//  ReCIT_iOSTests
//
//  The one way an author, a work or an edition gets into the store (`ModelContext+Entities`),
//  and the inventory sync that used to go round it. ADR 0001, invariant 2; issue 0067.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Entity upsert", .serialized)
struct EntityUpsertTests {

    // MARK: - Fixtures

    private func entity(_ uri: String, label: String, type: String = "work", claims: String = "{}") throws -> EntityResultDTO {
        try JSONDecoder().decode(EntityResultDTO.self, from: Data(entityJSON(uri, label: label, type: type, claims: claims).utf8))
    }

    private func entityJSON(_ uri: String, label: String, type: String = "work", claims: String = "{}") -> String {
        #"{"uri":"\#(uri)","lastrevid":1,"type":"\#(type)","labels":{"fr":"\#(label)"},"claims":\#(claims)}"#
    }

    private func envelope(_ bodies: String...) -> String {
        let entries: String = bodies.enumerated().map { #""e\#($0.offset)":\#($0.element)"# }.joined(separator: ",")
        return #"{"entities":{\#(entries)}}"#
    }

    private func author(_ uri: String, _ name: String) -> Author {
        .init(uri: uri, lastrevid: 1, name: name)
    }

    // MARK: - Works

    @Test("Upserting a work twice keeps one row and the same instance, and merges its fields")
    func workUpsertIsIdempotent() throws {
        let context: ModelContext = try TestStore.makeContext()
        let hugo: Author = author("wd:A1", "Hugo")
        context.insert(hugo)

        let first: Work = try context.upsertWork(try entity("wd:W1", label: "Old"), authors: [hugo], apiService: MockAPIService())
        try context.save()
        let second: Work = try context.upsertWork(try entity("wd:W1", label: "New"), authors: [hugo], apiService: MockAPIService())
        try context.save()

        #expect(second === first)
        #expect(try context.fetch(FetchDescriptor<Work>()).count == 1)
        #expect(first.title == "New")
        #expect(first.authors.map(\.uri) == ["wd:A1"])
        #expect(hugo.works.count == 1)
    }

    @Test("A work keeps what was stored locally when it is upserted again")
    func workUpsertKeepsLocalFields() throws {
        let context: ModelContext = try TestStore.makeContext()
        let work: Work = try context.upsertWork(try entity("wd:W1", label: "Germinal"), authors: [], apiService: MockAPIService())
        work.applyEnrichedGenres(["Roman naturaliste"])
        work.preferredEditionUri = "wd:E1"
        try context.save()

        try context.upsertWork(try entity("wd:W1", label: "Germinal"), authors: [], apiService: MockAPIService())
        try context.save()

        #expect(work.genres == ["Roman naturaliste"])
        #expect(work.genresEnrichedAt != nil)
        #expect(work.preferredEditionUri == "wd:E1")
    }

    @Test("A work received under each of its two authors keeps both")
    func workKeepsEveryAuthor() throws {
        let context: ModelContext = try TestStore.makeContext()
        let first: Author = author("wd:A1", "Deleuze")
        let second: Author = author("wd:A2", "Guattari")
        context.insert(first)
        context.insert(second)

        try context.upsertWork(try entity("wd:W1", label: "Mille plateaux"), authors: [first], apiService: MockAPIService())
        let work: Work = try context.upsertWork(try entity("wd:W1", label: "Mille plateaux"), authors: [second], apiService: MockAPIService())
        try context.save()

        #expect(Set(work.authors.map(\.uri)) == ["wd:A1", "wd:A2"])
        #expect(work.authors.count == 2)
    }

    // MARK: - Authors

    @Test("Authors already held are updated in place, the others inserted, once each")
    func authorsUpsert() throws {
        let context: ModelContext = try TestStore.makeContext()
        let held: Author = author("wd:A1", "Old name")
        context.insert(held)
        try context.save()

        let authors: [Author] = try context.upsertAuthors(
            [
                try entity("wd:A1", label: "Victor Hugo", type: "human"),
                try entity("wd:A2", label: "George Sand", type: "human"),
                try entity("wd:A2", label: "George Sand", type: "human")
            ],
            apiService: MockAPIService()
        )
        try context.save()

        #expect(authors.first === held)
        #expect(held.name == "Victor Hugo")
        #expect(authors[1] === authors[2])
        #expect(try context.fetch(FetchDescriptor<Author>()).count == 2)
    }

    // MARK: - Editions

    @Test("An item's edition is the one the store holds, works and colour intact")
    func snapshotEditionReusesTheHeldOne() throws {
        let context: ModelContext = try TestStore.makeContext()
        let work: Work = .init(uri: "wd:W1", lastrevid: 1, title: "Dune")
        let held: Edition = Fixture.edition(uri: "isbn:1", title: "Dune")
        held.works = [work]
        held.dominantColorHex = "#7A2E2E"
        context.insert(held)
        try context.save()

        let snapshot: EntitySnapshotDTO = try JSONDecoder().decode(
            EntitySnapshotDTO.self,
            from: Data(#"{"entity:title":"Dune (snapshot)"}"#.utf8)
        )
        let edition: Edition = try context.edition(uri: "isbn:1", snapshot: snapshot, apiService: MockAPIService())
        try context.save()

        #expect(edition === held)
        #expect(held.works.map(\.uri) == ["wd:W1"])
        #expect(held.dominantColorHex == "#7A2E2E")
        #expect(try context.fetch(FetchDescriptor<Edition>()).count == 1)
    }

    @Test("Upserting an edition adds its works without doubling them")
    func editionUpsertMergesWorks() throws {
        let context: ModelContext = try TestStore.makeContext()
        let work: Work = .init(uri: "wd:W1", lastrevid: 1, title: "Dune")
        context.insert(work)
        let dto: EntityResultDTO = try entity("wd:E1", label: "Dune", type: "edition")

        let first: Edition = try context.upsertEdition(dto, works: [work], apiService: MockAPIService())
        first.dominantColorHex = "#000000"
        let second: Edition = try context.upsertEdition(dto, works: [work], apiService: MockAPIService())
        try context.save()

        #expect(second === first)
        #expect(first.works.count == 1)
        #expect(first.dominantColorHex == "#000000")
    }

    // MARK: - The inventory sync

    private func stubInventory(_ mock: MockAPIService) {
        // One work under two authors, one copy of it.
        mock.stub("/api/items/inventory-view", json: """
        {"worksTree":{"author":{"wd:A1":["wd:W1"],"wd:A2":["wd:W1"]},"genre":{},"owner":{}},
         "workUriItemsMap":{"wd:W1":["item-1"]},"totalItems":1}
        """)
        mock.stub("uris=wd:W1&", json: envelope(entityJSON("wd:W1", label: "Mille plateaux")))
        mock.stub("uris=wd:A1&", json: envelope(entityJSON("wd:A1", label: "Deleuze", type: "human")))
        mock.stub("uris=wd:A2&", json: envelope(entityJSON("wd:A2", label: "Guattari", type: "human")))
        mock.stub("/api/items/by-ids", json: """
        {"items":[{"_id":"item-1","_rev":"1","entity":"isbn:1","transaction":"inventorying",
          "visibility":["public"],"owner":"user-1","created":1700000000000,
          "snapshot":{"entity:title":"Mille plateaux"}}],"total":1,"offset":0}
        """)
    }

    @Test("Syncing an inventory twice keeps its works, their authors and what was stored on them")
    func inventorySyncUpsertsWorks() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        stubInventory(mock)
        let entityModel: EntityModel = .init(apiService: mock)
        let inventoryModel: InventoryModel = .init(apiService: mock)
        inventoryModel.start(entityModel: entityModel, errorReporter: .init())
        let user: User = Fixture.user()
        context.insert(user)
        try context.save()

        try await inventoryModel.syncInventory(forUser: user, modelContext: context)

        let held: Work = try #require(try context.fetch(FetchDescriptor<Work>()).first)
        held.applyEnrichedGenres(["Philosophie"])
        let edition: Edition = try #require(try context.fetch(FetchDescriptor<Edition>()).first)
        edition.dominantColorHex = "#123456"
        try context.save()

        user.lastInventorySync = nil
        try await inventoryModel.syncInventory(forUser: user, modelContext: context)

        let works: [Work] = try context.fetch(FetchDescriptor<Work>())
        #expect(works.count == 1)
        #expect(works.first === held)
        #expect(held.isStillInTheStore)
        #expect(held.genres == ["Philosophie"])
        #expect(Set(held.authors.map(\.uri)) == ["wd:A1", "wd:A2"])
        #expect(try context.fetch(FetchDescriptor<Edition>()).count == 1)
        #expect(edition.works.map(\.uri) == ["wd:W1"])
        #expect(edition.dominantColorHex == "#123456")
        #expect(try context.fetch(FetchDescriptor<InventoryItem>()).count == 1)
    }
}
