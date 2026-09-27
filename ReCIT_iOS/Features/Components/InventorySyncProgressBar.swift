//
//  InventorySyncProgressBar.swift
//  ReCIT_iOS
//
//  The bar of a first inventory sync: items received over items announced. Empty while the
//  sync waits for its turn or for its total — a bar that moved before there was anything to
//  measure would be a bar that lies.
//

import SwiftUI

struct InventorySyncProgressBar: View {
    let state: InventoryFirstSyncState

    private var fraction: Double {
        switch state {
        case .synced: 1
        case .waiting: 0
        case let .running(progress): progress.fraction ?? 0
        }
    }

    var body: some View {
        ProgressView(value: fraction)
            .progressViewStyle(.linear)
            .tint(.foregroundTinted)
            .animation(.default, value: fraction)
    }
}

#Preview {
    VStack(spacing: .medium) {
        InventorySyncProgressBar(state: .waiting)
        InventorySyncProgressBar(state: .running(.init(workUriItemsMap: ["wd:1": ["a", "b", "c", "d"]])))
        InventorySyncProgressBar(state: .synced)
    }
    .padding(.all, .medium)
}
