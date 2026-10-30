//
//  OwnedInventoryTabTitle.swift
//  ReCIT_iOS
//

import SwiftData
import SwiftUI

/// « Inventaire • 540 » on my own profile, counted in the store like `OwnedItemCountText`, so it
/// moves the moment a book is scanned in or removed.
struct OwnedInventoryTabTitle: View {
    @Query private var items: [InventoryItem]

    init(ownerId: String) {
        _items = Query(filter: #Predicate<InventoryItem> { $0.ownerId == ownerId })
    }

    var body: some View {
        UserProfileTabLabel.inventoryTitle(count: items.count)
    }
}
