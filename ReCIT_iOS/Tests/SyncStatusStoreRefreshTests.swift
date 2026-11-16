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
    private func makeStore() -> SyncStatusStore {
        let defaults: UserDefaults = .init(suiteName: UUID().uuidString) ?? .standard
        return .init(defaults: defaults)
    }

    @Test
    func `a second refresh is refused while the first runs`() {
        let store: SyncStatusStore = makeStore()

        #expect(store.beginRefresh())
        #expect(store.beginRefresh() == false)
    }

    @Test
    func `a refresh can start again once the previous one has ended`() {
        let store: SyncStatusStore = makeStore()

        #expect(store.beginRefresh())
        store.endRefresh()

        #expect(store.beginRefresh())
    }
}
