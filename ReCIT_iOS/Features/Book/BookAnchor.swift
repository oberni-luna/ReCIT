//
//  BookAnchor.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation

/// Names an entry point into the unified book screen. Both cases resolve to a
/// single `Edition` — the ownable / physical unit a user intuitively calls
/// "a book". An `InventoryItem` is just "my copy of that edition", so it anchors
/// to the same screen rather than a separate one. (ADR 0002, Move 1)
enum BookAnchor: Hashable {
    /// Arrived from search, a list, or a work's edition gateway.
    case edition(uri: String)

    /// Arrived from an inventory item — resolves to `item.edition`.
    case item(InventoryItem)

    /// The URI of the edition this anchor resolves to, or `nil` when an item's
    /// `edition` relationship is not yet hydrated (an edge case the view model
    /// surfaces as "no result").
    var editionUri: String? {
        switch self {
        case .edition(let uri):
            uri
        case .item(let item):
            item.edition?.uri
        }
    }

    /// Stable identity for the navigation stack, so the same book is a single
    /// entry regardless of which anchor pushed it.
    var stableId: String {
        switch self {
        case .edition(let uri):
            "edition:\(uri)"
        case .item(let item):
            "item:\(item._id)"
        }
    }

    // Equatable / Hashable are defined on `stableId` rather than synthesized:
    // the `.item` case carries a SwiftData `@Model`, whose synthesized
    // conformance does not compose cleanly into this enum under strict
    // concurrency. `stableId` is the navigation identity, so this is also the
    // semantically correct notion of equality here.
    static func == (lhs: BookAnchor, rhs: BookAnchor) -> Bool {
        lhs.stableId == rhs.stableId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stableId)
    }
}
