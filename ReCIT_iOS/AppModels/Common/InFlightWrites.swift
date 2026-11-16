//
//  InFlightWrites.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/11/2026.
//

import Foundation
import SwiftData
import Synchronization

/// The models a user-initiated write has changed locally and is still sending to inventaire.io.
///
/// A sync brings back server state one round trip behind such a write: merged into the model,
/// it would undo on screen what the reader has just done. So the optimistic writes and the
/// étagère membership writes enter their models here for as long as they run, and a sync leaves
/// those models alone. A `Mutex` rather than an actor: the inventory sync asks about each item
/// synchronously, from its own actor (ADR 0009).
///
/// Counted rather than a set: two writes on one model overlap, and the first to end must not
/// free the model the second still holds.
nonisolated final class InFlightWrites: Sendable {
    static let shared: InFlightWrites = .init()

    private let writeCounts: Mutex<[PersistentIdentifier: Int]> = .init([:])

    func begin(_ ids: [PersistentIdentifier]) {
        writeCounts.withLock { counts in
            for id in ids {
                counts[id, default: 0] += 1
            }
        }
    }

    func end(_ ids: [PersistentIdentifier]) {
        writeCounts.withLock { counts in
            for id in ids {
                let remaining: Int = counts[id, default: 0] - 1
                counts[id] = remaining > 0 ? remaining : nil
            }
        }
    }

    func contains(_ id: PersistentIdentifier) -> Bool {
        writeCounts.withLock { $0[id] != nil }
    }
}
