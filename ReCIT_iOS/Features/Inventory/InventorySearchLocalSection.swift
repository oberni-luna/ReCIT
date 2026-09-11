//
//  InventorySearchLocalSection.swift
//  ReCIT_iOS
//
//  One section, mixing my books and my friends' copies, capped at three. It is the first half
//  of the merged search: what the app can answer without touching the network.
//
//  The ordering and the cap belong to `InventorySearchRanking`, which this view feeds with the
//  copies it holds and reads back in order (`rankItems`). Going through that one function —
//  rather than sorting the models here — keeps the rule testable without a `ModelContainer`,
//  keeps this file to the one thing a view should do, and is what lets the screen behind
//  « Tout voir » list the same books in the same order without a second sort.
//
//  **« Tout voir » appears only when the cap actually hides something** — when the uncapped
//  total is more than three, never when it is exactly three. The cap exists so the road to
//  inventaire.io stays above the keyboard; it must never be the reason a book cannot be found,
//  so the total the ranking returns buys a way past it. Where it leads was the open question of
//  issue 0075, settled in favour of a screen of its own: `NavigationDestination
//  .localSearchResults`, pushed onto the inventory tab's own path like every other row here.
//
//  A book whose row has gone (the copy was deleted while the list was still on screen) never
//  becomes a candidate: reading a persisted property off an invalidated model is a hard trap,
//  not a nil. See `PersistentModel+StillInTheStore` and issue 0065.
//
//  The header is first-person — « Dans mes livres et chez mes amis » — rather than the
//  catalogue's `search.friends_inventory`, which was the only tutoiement in it and went with
//  the search tab at issue 0074. The screen « Tout voir » leads to wears the same title: it is
//  the same answer, uncapped, and two names for it would read as two places.
//
//  See PRD 0012.
//

import SwiftUI

struct InventorySearchLocalSection: View {
    let query: String
    let ownerId: String
    let myItems: [InventoryItem]
    let friendsItems: [InventoryItem]

    /// The items the section shows and the uncapped total behind them, in the order the
    /// ranking decided.
    private var outcome: InventorySearchRanking.ItemOutcome {
        InventorySearchRanking.rankItems(
            myItems + friendsItems,
            matching: query,
            ownerId: ownerId
        )
    }

    var body: some View {
        let ranked: InventorySearchRanking.ItemOutcome = outcome

        // No match means no section: an empty header under the field would read as a screen
        // that failed rather than as a library that holds nothing. What to say instead is
        // issue 0076's question.
        if !ranked.items.isEmpty {
            Section {
                ForEach(ranked.items) { item in
                    NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                        // A friend's copy names its owner; mine has no reason to.
                        InventoryCell(
                            item: item,
                            filterParameter: item.ownerId == ownerId ? .userInventory : .othersInventory
                        )
                    }
                }
            } header: {
                InventorySearchLocalHeader(
                    query: query,
                    showsSeeAll: ranked.totalCount > InventorySearchRanking.displayLimit
                )
            }
        }
    }
}
