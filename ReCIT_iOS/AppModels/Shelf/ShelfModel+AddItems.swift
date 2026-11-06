//
//  ShelfModel+AddItems.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  One book filed from the "…" menu: the batch `addItems` with a single book in it, so both
//  routes go through the same optimistic write.
//

import Foundation
import SwiftData

extension ShelfModel {
    /// Files one book onto an étagère, optimistically. See `addItems(_:to:modelContext:)`.
    func addItem(
        _ item: InventoryItem,
        to shelf: Shelf,
        modelContext: ModelContext
    ) {
        addItems([item], to: shelf, modelContext: modelContext)
    }
}
