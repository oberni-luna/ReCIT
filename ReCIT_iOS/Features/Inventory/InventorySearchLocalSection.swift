//
//  InventorySearchLocalSection.swift
//  ReCIT_iOS
//
//  One section, mixing my books and my friends' copies, capped at three. It is the first half
//  of the merged search: what the app can answer without touching the network.
//
//  The ordering and the cap belong to `InventorySearchRanking`, which this view feeds with
//  plain values and reads back as ids. Going through ids rather than sorting the models keeps
//  the rule testable without a `ModelContainer` — and keeps this file to the one thing a view
//  should do, which is draw.
//
//  A book whose row has gone (the copy was deleted while the list was still on screen) never
//  becomes a candidate: reading a persisted property off an invalidated model is a hard trap,
//  not a nil. See `PersistentModel+StillInTheStore` and issue 0065.
//
//  The header is first-person — « Dans mes livres et chez mes amis » — rather than the
//  catalogue's `search.friends_inventory`, which is its only tutoiement and dies with
//  `SearchView` at issue 0074.
//
//  See PRD 0012.
//

import SwiftUI

struct InventorySearchLocalSection: View {
    let query: String
    let ownerId: String
    let myItems: [InventoryItem]
    let friendsItems: [InventoryItem]

    /// The items the section shows, in the order the ranking decided. The uncapped total the
    /// ranking also returns is what « Tout voir » will read (issue 0075); nothing displays it
    /// yet.
    private var rankedItems: [InventoryItem] {
        let items: [InventoryItem] = (myItems + friendsItems).filter(\.isStillInTheStore)
        let byId: [String: InventoryItem] = .init(
            items.map { ($0._id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let candidates: [InventorySearchRanking.Candidate] = items.map { item in
            .init(
                id: item._id,
                searchIndex: item.searchIndex,
                isMine: item.ownerId == ownerId,
                created: item.created
            )
        }

        return InventorySearchRanking
            .rank(candidates, matching: query)
            .matches
            .compactMap { byId[$0.id] }
    }

    var body: some View {
        let items: [InventoryItem] = rankedItems

        // No match means no section: an empty header under the field would read as a screen
        // that failed rather than as a library that holds nothing. What to say instead is
        // issue 0076's question.
        if !items.isEmpty {
            Section("inventory.search.local_section") {
                ForEach(items) { item in
                    NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                        // A friend's copy names its owner; mine has no reason to.
                        InventoryCell(
                            item: item,
                            filterParameter: item.ownerId == ownerId ? .userInventory : .othersInventory
                        )
                    }
                }
            }
        }
    }
}
