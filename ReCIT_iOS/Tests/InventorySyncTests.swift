//
//  InventorySyncTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 11/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct InventorySyncTests {
    @Test
    func `a sync leaves its items in the store for the main context, and does not write it`() async throws {
        let container: ModelContainer = try TestStore.makeContainer()
        let context: ModelContext = container.mainContext
        let user: User = try storedUser(in: context)
        let model: InventoryModel = .init(apiService: stubbedInventory())

        try await model.syncInventory(forUser: user, modelContext: context)

        let items: [InventoryItem] = try context.fetch(FetchDescriptor<InventoryItem>())
        #expect(items.count == 3)
        #expect(items.allSatisfy { $0.edition?.works.isEmpty == false })
        #expect(user.lastInventorySync != nil)
        #expect(context.hasChanges == false)
    }

    @Test
    func `an item with a write in flight keeps what the reader wrote`() async throws {
        let container: ModelContainer = try TestStore.makeContainer()
        let context: ModelContext = container.mainContext
        _ = try storedUser(in: context)
        let item: InventoryItem = Fixture.inventoryItem(id: "item-1", edition: Fixture.edition())
        item.details = "Ce que j'en pense"
        context.insert(item)
        try context.save()
        let writes: InFlightWrites = .init()
        writes.begin([item.persistentModelID])
        let sync: InventorySync = .init(
            modelContainer: container,
            apiService: stubbedInventory(),
            inFlightWrites: writes
        )

        _ = try await sync.sync(userID: "user-1", progress: AsyncStream<InventorySyncProgress>.makeStream().continuation)

        let stored: [String: String] = try storedDetails(in: container)
        #expect(stored["item-1"] == "Ce que j'en pense")
        #expect(stored["item-2"] == "Selon le serveur")
    }

    @Test
    func `a sync saves no more often than its interval, and always once at the end`() async throws {
        #expect(try await progressReports(savingEvery: .seconds(3600)) == 2)
        #expect(try await progressReports(savingEvery: .zero) == 5)
    }

    /// How many times a sync of three authors reports its progress: once announced, then at
    /// each save.
    private func progressReports(savingEvery interval: Duration) async throws -> Int {
        let container: ModelContainer = try TestStore.makeContainer()
        _ = try storedUser(in: container.mainContext)
        let sync: InventorySync = .init(
            modelContainer: container,
            apiService: stubbedInventory(),
            saveInterval: interval
        )
        let (updates, progress): (AsyncStream<InventorySyncProgress>, AsyncStream<InventorySyncProgress>.Continuation) = AsyncStream.makeStream()

        _ = try await sync.sync(userID: "user-1", progress: progress)

        var reports: Int = 0
        for await _ in updates {
            reports += 1
        }
        return reports
    }

    private func storedUser(in context: ModelContext) throws -> User {
        let user: User = Fixture.user()
        context.insert(user)
        try context.save()
        return user
    }

    /// Each item's comment as the store holds it, read through a context of its own.
    private func storedDetails(in container: ModelContainer) throws -> [String: String] {
        let items: [InventoryItem] = try ModelContext(container).fetch(FetchDescriptor<InventoryItem>())
        return .init(uniqueKeysWithValues: items.map { ($0._id, $0.details) })
    }

    /// Three authors, a work each, a copy of each work.
    private func stubbedInventory() -> MockAPIService {
        let mock: MockAPIService = .init()
        mock.stub("/api/items/inventory-view", json: """
        {"worksTree":{"author":{"wd:A1":["wd:W1"],"wd:A2":["wd:W2"],"wd:A3":["wd:W3"]},"genre":{},"owner":{}},
         "workUriItemsMap":{"wd:W1":["item-1"],"wd:W2":["item-2"],"wd:W3":["item-3"]},"totalItems":3}
        """)
        for index in 1...3 {
            mock.stub("uris=wd:A\(index)&", json: entities(uri: "wd:A\(index)", label: "Auteur·ice \(index)", type: "human"))
            mock.stub("uris=wd:W\(index)&", json: entities(uri: "wd:W\(index)", label: "Œuvre \(index)", type: "work"))
            mock.stub("ids=item-\(index)", json: items(id: "item-\(index)"))
        }
        return mock
    }

    private func entities(uri: String, label: String, type: String) -> String {
        #"{"entities":{"e0":{"uri":"\#(uri)","lastrevid":1,"type":"\#(type)","labels":{"fr":"\#(label)"},"claims":{}}}}"#
    }

    private func items(id: String) -> String {
        """
        {"items":[{"_id":"\(id)","_rev":"2","entity":"isbn:\(id)","transaction":"inventorying",
          "details":"Selon le serveur","visibility":["public"],"owner":"user-1",
          "created":1700000000000,"snapshot":{"entity:title":"Titre"}}],"total":1,"offset":0}
        """
    }
}
