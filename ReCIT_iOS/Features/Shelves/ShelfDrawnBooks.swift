//
//  ShelfDrawnBooks.swift
//  ReCIT_iOS
//
//  The books a shelf actually draws: newest first, capped so a huge shelf doesn't render
//  hundreds of spines (the overflow stays reachable through the shelf's list). Shared by the
//  shelf card and the focus overlay so both draw the same run.
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
        Array(items.sorted { $0.created > $1.created }.prefix(limit))
    }
}
