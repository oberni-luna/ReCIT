//
//  SyncStatusStoreRefreshTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("SyncStatusStore refresh")
struct SyncStatusStoreRefreshTests {
    @Test
    func `a second refresh is refused while the first runs`() {
        let store: SyncStatusStore = makeStore()

        #expect(store.beginRefresh() != nil)
        #expect(store.beginRefresh() == nil)
    }

    @Test
    func `a refresh can start again once the previous one has ended`() throws {
        let store: SyncStatusStore = makeStore()

        let claim: SyncStatusStore.RefreshClaim = try #require(store.beginRefresh())
        store.endRefresh(claim)

        #expect(store.beginRefresh() != nil)
    }

    @Test
    func `a reset during a run lets a new refresh start, which the old run's end does not release`() throws {
        let store: SyncStatusStore = makeStore()
        let oldClaim: SyncStatusStore.RefreshClaim = try #require(store.beginRefresh())

        store.reset()
        let newClaim: SyncStatusStore.RefreshClaim = try #require(store.beginRefresh())
        store.endRefresh(oldClaim)

        #expect(store.beginRefresh() == nil)
        store.endRefresh(newClaim)
        #expect(store.beginRefresh() != nil)
    }

    private func makeStore() -> SyncStatusStore {
        let defaults: UserDefaults = .init(suiteName: UUID().uuidString) ?? .standard
        return .init(defaults: defaults)
    }
}
