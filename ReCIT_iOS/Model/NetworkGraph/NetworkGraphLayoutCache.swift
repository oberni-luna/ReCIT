//
//  NetworkGraphLayoutCache.swift
//  ReCIT_iOS
//
//  The placements already computed, by fingerprint (PRD 0019, Q45): reopening « Tout » on the
//  same network with the same text size finds its graph at once instead of relaxing it again,
//  and a sync that changes nothing the graph draws costs a lookup.
//
//  The fingerprint is the `NetworkGraphLayout` itself — the shape of the graph and every
//  measured box, nothing the placement does not read. A few entries are kept, the oldest dropped
//  first: the network one is looking at, and the one it just was.
//
//  Shared across threads behind a `Mutex`: the screen asks it on the main actor, and the
//  placement it does not hold is computed off it.
//

import Foundation
import Synchronization

nonisolated final class NetworkGraphLayoutCache: Sendable {
    /// The one the Réseau tab reads, for as long as the app runs.
    static let shared: NetworkGraphLayoutCache = .init()

    private let capacity: Int
    private let storage: Mutex<Storage> = .init(.init())

    init(capacity: Int = 4) {
        self.capacity = max(capacity, 1)
    }

    /// The placement of `layout` if it was computed already.
    func cachedPlacement(for layout: NetworkGraphLayout) -> NetworkGraphPlacement? {
        storage.withLock { $0.entries[layout] }
    }

    /// The placement of `layout`, from the cache or computed and kept. Synchronous and pure:
    /// call it off the main actor.
    func placement(for layout: NetworkGraphLayout) -> NetworkGraphPlacement {
        if let cached = cachedPlacement(for: layout) {
            return cached
        }
        let placement: NetworkGraphPlacement = layout.placement()
        storage.withLock { storage in
            if storage.entries.updateValue(placement, forKey: layout) == nil {
                storage.order.append(layout)
            }
            while storage.order.count > capacity {
                storage.entries[storage.order.removeFirst()] = nil
            }
        }
        return placement
    }

    /// The placement of `layout`, computed off the main actor when it is not cached.
    func placementOffMainActor(for layout: NetworkGraphLayout) async -> NetworkGraphPlacement {
        if let cached = cachedPlacement(for: layout) {
            return cached
        }
        return await Task.detached(priority: .userInitiated) { [self] in
            placement(for: layout)
        }.value
    }

    /// How many placements are kept.
    var count: Int {
        storage.withLock { $0.entries.count }
    }

    private nonisolated struct Storage: Sendable {
        var entries: [NetworkGraphLayout: NetworkGraphPlacement] = [:]
        /// The keys, oldest first.
        var order: [NetworkGraphLayout] = []
    }
}
