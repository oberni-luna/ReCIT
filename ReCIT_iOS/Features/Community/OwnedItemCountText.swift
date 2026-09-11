//
//  OwnedItemCountText.swift
//  ReCIT_iOS
//

import SwiftUI
import SwiftData

/// How many books a user actually holds, counted in the local store.
///
/// Bound to a `@Query` rather than to the server's `snapshot` count, so it answers the moment
/// the inventory changes: scanning a book in or removing one redraws the number straight away,
/// and it stays right offline. The server's own count only moves on its next snapshot, which is
/// why the profile header used to sit on a stale figure for the whole life of the app.
struct OwnedItemCountText: View {
    @Query private var items: [InventoryItem]

    init(ownerId: String) {
        _items = Query(filter: #Predicate<InventoryItem> { $0.ownerId == ownerId })
    }

    var body: some View {
        Text("user.item_count \(items.count)")
    }
}
