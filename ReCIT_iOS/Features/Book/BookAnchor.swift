//
//  BookAnchor.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation

/// Names an entry point into the unified book screen. Every case resolves to a
/// single `Edition` — the ownable / physical unit a user intuitively calls
/// "a book". An `InventoryItem` is just "my copy of that edition", so it anchors
/// to the same screen rather than a separate one. (ADR 0002, Moves 1 and 3)
enum BookAnchor: Hashable {
    /// Arrived from a list, or a work's edition gateway.
    case edition(uri: String)

    /// Arrived from an inventory item — resolves to `item.edition`.
    case item(InventoryItem)

    /// Arrived from a search result. `/api/search` cannot return editions, so the
    /// server answered with a work and the app picks the edition itself — over the
    /// network, at tap, through `EditionRelevance` (ADR 0002, Move 3).
    ///
    /// The title and image ride along because the search result already holds them:
    /// they cost nothing, and they are what fills the header while the resolution is
    /// in flight, instead of a spinner on a blank screen. They are display only —
    /// `stableId` stays derived from the uri alone, so the same work is one entry in
    /// the stack however it was labelled.
    case bestEditionOfWork(uri: String, title: String, imageUrl: String?)

    /// The URI of the edition this anchor resolves to, or `nil` when an item's
    /// `edition` relationship is not yet hydrated (an edge case the view model
    /// surfaces as "no result").
    ///
    /// `.bestEditionOfWork` answers `nil` on purpose: which edition it means is a
    /// question for the network, not for a computed property. `BookViewModel.load`
    /// branches on the anchor **before** it consults this, so the case never reaches
    /// the `guard` that would read the `nil` as "no such book".
    var editionUri: String? {
        switch self {
        case .edition(let uri):
            uri
        case .item(let item):
            item.edition?.uri
        case .bestEditionOfWork:
            nil
        }
    }

    /// What to draw while an anchor that needs the network resolves. `nil` for the
    /// anchors that resolve instantly and have nothing to stand in for.
    var placeholder: Placeholder? {
        switch self {
        case .edition, .item:
            nil
        case .bestEditionOfWork(_, let title, let imageUrl):
            .init(title: title, imageUrl: imageUrl)
        }
    }

    /// The header the screen wears until the real edition lands: the work's title and
    /// cover, as the search result gave them.
    struct Placeholder: Hashable, Sendable {
        let title: String
        let imageUrl: String?
    }

    /// Stable identity for the navigation stack, so the same book is a single
    /// entry regardless of which anchor pushed it.
    var stableId: String {
        switch self {
        case .edition(let uri):
            "edition:\(uri)"
        case .item(let item):
            "item:\(item._id)"
        case .bestEditionOfWork(let uri, _, _):
            "work:\(uri)"
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
