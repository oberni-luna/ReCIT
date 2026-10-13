//
//  UserDataSyncTests.swift
//  ReCIT_iOSTests
//
//  The order of a launch's sync, read off the calls it makes (Q11c of PRD 0019): my user, my
//  étagères, my relations and then my groups — the whole network — before my inventory, then
//  my lists and my transactions.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("UserDataSync")
struct UserDataSyncTests {

    private func makeSync(
        _ mock: MockAPIService,
        syncStatus: SyncStatusStore,
        defaults: UserDefaults
    ) -> UserDataSync {
        .init(
            userModel: .init(apiService: mock),
            shelfModel: .init(apiService: mock),
            inventoryModel: .init(apiService: mock),
            entityModel: .init(apiService: mock),
            transactionModel: .init(apiService: mock),
            groupModel: .init(apiService: mock, ledger: .init(defaults: defaults), defaults: defaults),
            listModel: .init(apiService: mock),
            syncStatus: syncStatus,
            errorReporter: .init(),
            onSessionGone: {}
        )
    }

    @Test("The groups are asked for right after the relations, and before my inventory")
    func groupsBeforeInventory() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let defaults: UserDefaults = UserDefaults(suiteName: "user-data-sync-\(UUID().uuidString)") ?? .standard
        let syncStatus: SyncStatusStore = .init(defaults: defaults)
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"_id":"me","username":"me"}"#)
        mock.stub("/api/relations", json: #"{"friends":[],"userRequested":[],"otherRequested":[],"network":[]}"#)
        mock.stub("/api/groups", json: #"{"groups":[]}"#)
        // Everything else answers 404: each step fails on its own, and the next one still runs.

        await makeSync(mock, syncStatus: syncStatus, defaults: defaults).run(modelContext: context)

        let endpoints: [String] = mock.recordedRequests.map(\.endpoint)
        let steps: [String] = [
            "/api/user",
            "/api/shelves",
            "/api/relations",
            "/api/groups",
            "/api/items/inventory-view",
            "/api/lists/by-creators",
            "/api/transactions"
        ]
        let firstCalls: [Int?] = steps.map { step in endpoints.firstIndex { $0.hasPrefix(step) } }
        #expect(firstCalls.allSatisfy { $0 != nil }, "every step reaches the server: \(endpoints)")
        let order: [Int] = firstCalls.compactMap(\.self)
        #expect(order == order.sorted(), "steps out of order: \(endpoints)")
        #expect(syncStatus.hasCompletedFirstSync(.groups))
    }

    @Test("A failed groups sync is said in memory, and does not stop my inventory")
    func failedGroupsSync() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let defaults: UserDefaults = UserDefaults(suiteName: "user-data-sync-\(UUID().uuidString)") ?? .standard
        let syncStatus: SyncStatusStore = .init(defaults: defaults)
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"_id":"me","username":"me"}"#)
        mock.stub("/api/groups", error: URLError(.notConnectedToInternet))

        await makeSync(mock, syncStatus: syncStatus, defaults: defaults).run(modelContext: context)

        #expect(syncStatus.phase(.groups) == .failed)
        #expect(SyncStatusStore(defaults: defaults).hasCompletedFirstSync(.groups) == false)
        #expect(mock.recordedRequests.contains { $0.endpoint.hasPrefix("/api/items/inventory-view") })
    }
}
