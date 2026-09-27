//
//  InventorySyncProgress.swift
//  ReCIT_iOS
//
//  How far a first inventory sync has got: items received against items announced.
//
//  Counted in distinct item ids on both sides. `inventory-view` files an item under every work
//  its edition belongs to, so the same id can come back under two works; counting requests
//  rather than ids would push the bar past its end on a collection of omnibuses.
//

import Foundation

struct InventorySyncProgress: Equatable, Sendable {
    /// Items announced by `inventory-view`. `nil` until that first answer lands — the only
    /// moment of the sync where there is nothing honest to measure against.
    let total: Int?
    private(set) var receivedIds: Set<String> = []

    init(total: Int? = nil) {
        self.total = total
    }

    /// The progress of a sync whose `inventory-view` has answered with `workUriItemsMap`.
    init(workUriItemsMap: [String: [String]]) {
        self.total = Set(workUriItemsMap.values.joined()).count
    }

    var received: Int {
        receivedIds.count
    }

    /// Between 0 and 1, or `nil` while the total is unknown. An empty inventory is complete.
    var fraction: Double? {
        guard let total else { return nil }
        guard total > 0 else { return 1 }
        return min(1, Double(received) / Double(total))
    }

    mutating func receive(_ ids: [String]) {
        receivedIds.formUnion(ids)
    }
}
