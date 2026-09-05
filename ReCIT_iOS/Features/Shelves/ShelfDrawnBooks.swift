//
//  ShelfDrawnBooks.swift
//  ReCIT_iOS
//
//  The books a shelf actually draws: the ones with a cover first, newest first within each
//  group, capped so a huge shelf doesn't render hundreds of spines (the overflow stays
//  reachable through the shelf's list). Shared by the shelf card and the focus overlay so
//  both draw the same run.
//
//  Covers come first because a spine is painted from its cover: a book without one is a
//  flat sheet of parchment, and a shelf of those reads as broken rather than as a shelf.
//  With a cap of 20 on a collection of any size, that ordering usually means every drawn
//  book is painted.
//
//  Deliberately not an extension on `Shelf`: extending that `@Model` class with a member
//  returning `[InventoryItem]` breaks its macro expansion, which surfaces as an unrelated
//  "does not conform to Hashable" error in another file entirely. See ADR 0006.
//

import Foundation

enum ShelfDrawnBooks {
    /// Cap on how many books one étagère draws.
    static let limit: Int = 20

    static func from(_ items: [InventoryItem]) -> [InventoryItem] {
        let sorted: [InventoryItem] = items.sorted { first, second in
            let firstHasCover: Bool = hasCover(first)
            let secondHasCover: Bool = hasCover(second)
            if firstHasCover != secondHasCover { return firstHasCover }
            return first.created > second.created
        }
        return Array(sorted.prefix(limit))
    }

    /// Whether this copy has cover art to paint its spine with.
    private static func hasCover(_ item: InventoryItem) -> Bool {
        guard let image = item.edition?.image else { return false }
        return image.isEmpty == false
    }
}
