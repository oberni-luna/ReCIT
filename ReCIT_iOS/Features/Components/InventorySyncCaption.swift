//
//  InventorySyncCaption.swift
//  ReCIT_iOS
//
//  The words under a first sync's bar: how many books have arrived out of how many, or why
//  there is no figure yet.
//

import SwiftUI

struct InventorySyncCaption: View {
    let state: InventoryFirstSyncState

    var body: some View {
        switch state {
        case .synced:
            EmptyView()
        case .waiting:
            Text("sync.inventory.waiting")
        case let .running(progress):
            if let total = progress.total {
                Text("sync.inventory.count \(progress.received) \(total)")
            } else {
                Text("sync.inventory.preparing")
            }
        }
    }
}
