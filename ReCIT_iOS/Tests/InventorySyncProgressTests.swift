//
//  InventorySyncProgressTests.swift
//  ReCIT_iOSTests
//
//  The bar of a first inventory sync: what it counts, when it is full, and what a screen reads
//  of a user's inventory before, during and after that sync.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@Suite("InventorySyncProgress")
struct InventorySyncProgressTests {

    @Test("The total counts each item once, however many works it is filed under")
    func totalCountsDistinctIds() {
        let progress: InventorySyncProgress = .init(workUriItemsMap: [
            "wd:Q1": ["a", "b"],
            "wd:Q2": ["b", "c"]
        ])

        #expect(progress.total == 3)
        #expect(progress.fraction == 0)
    }

    @Test("An item received twice is counted once, and the bar never passes its end")
    func receivingIsIdempotent() {
        var progress: InventorySyncProgress = .init(workUriItemsMap: ["wd:Q1": ["a", "b"], "wd:Q2": ["b"]])

        progress.receive(["a", "b"])
        progress.receive(["b"])

        #expect(progress.received == 2)
        #expect(progress.fraction == 1)
    }

    @Test("Half the items received is half the bar")
    func fractionIsReceivedOverTotal() {
        var progress: InventorySyncProgress = .init(workUriItemsMap: ["wd:Q1": ["a", "b", "c", "d"]])

        progress.receive(["a", "b"])

        #expect(progress.fraction == 0.5)
    }

    @Test("No fraction before the total is known")
    func unknownTotalHasNoFraction() {
        #expect(InventorySyncProgress().fraction == nil)
    }

    @Test("An empty inventory is complete")
    func emptyInventoryIsComplete() {
        #expect(InventorySyncProgress(workUriItemsMap: [:]).fraction == 1)
    }
}

@Suite("InventoryFirstSyncState")
struct InventoryFirstSyncStateTests {

    @Test("A user synced once is synced, whatever else is running")
    func syncedWinsOverProgress() {
        #expect(InventoryFirstSyncState(lastInventorySync: 1, progress: .init()) == .synced)
    }

    @Test("Never synced and nothing running is waiting")
    func neverSyncedIsWaiting() {
        #expect(InventoryFirstSyncState(lastInventorySync: nil, progress: nil) == .waiting)
    }

    @Test("Never synced with a sync under way is running")
    func runningCarriesItsProgress() {
        let progress: InventorySyncProgress = .init(workUriItemsMap: ["wd:Q1": ["a"]])

        #expect(InventoryFirstSyncState(lastInventorySync: nil, progress: progress) == .running(progress))
    }
}

@MainActor
@Suite("InventoryModel first sync", .serialized)
struct InventoryModelFirstSyncTests {

    private let inventoryView: String = """
    {
      "worksTree": { "author": {}, "genre": {}, "owner": {} },
      "workUriItemsMap": { "wd:Q1": ["a", "b"], "wd:Q2": ["b", "c"] },
      "totalItems": 3
    }
    """

    @Test("A first sync that lands leaves the user synced and no bar behind")
    func landedSyncClearsItsProgress() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let friend: User = Fixture.user(id: "friend", username: "Camille")
        context.insert(friend)
        let mock: MockAPIService = .init()
        mock.stub("/api/items/inventory-view", json: inventoryView)
        let model: InventoryModel = .init(apiService: mock)
        model.start(entityModel: .init(apiService: mock), errorReporter: .init())

        try await model.syncInventory(forUser: friend, modelContext: context)

        #expect(friend.lastInventorySync != nil)
        #expect(model.firstSyncProgress.isEmpty)
        #expect(model.firstSyncState(for: friend) == .synced)
    }

    @Test("A first sync that fails sends the user back to waiting")
    func failedSyncIsWaitingAgain() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let friend: User = Fixture.user(id: "friend", username: "Camille")
        context.insert(friend)
        let mock: MockAPIService = .init()
        mock.stub("/api/items/inventory-view", error: NetworkError.badResponse)
        let model: InventoryModel = .init(apiService: mock)

        await #expect(throws: NetworkError.self) {
            try await model.syncInventory(forUser: friend, modelContext: context)
        }

        #expect(friend.lastInventorySync == nil)
        #expect(model.firstSyncState(for: friend) == .waiting)
    }
}
