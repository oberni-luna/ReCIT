//
//  InventoryFirstSyncState.swift
//  ReCIT_iOS
//
//  Where a user's inventory stands with respect to its first sync — the only sync a screen
//  shows. Later refreshes land on books already there and say nothing.
//

import Foundation

enum InventoryFirstSyncState: Equatable, Sendable {
    /// Synced at least once: the local store is the inventory.
    case synced
    /// Never synced, and not being synced right now — still in the queue behind someone else's,
    /// or the last attempt failed and the next refresh will try again.
    case waiting
    /// A first sync is running.
    case running(InventorySyncProgress)

    init(lastInventorySync: Double?, progress: InventorySyncProgress?) {
        if lastInventorySync != nil {
            self = .synced
        } else if let progress {
            self = .running(progress)
        } else {
            self = .waiting
        }
    }
}
