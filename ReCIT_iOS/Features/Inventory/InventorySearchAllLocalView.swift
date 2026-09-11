//
//  InventorySearchAllLocalView.swift
//  ReCIT_iOS
//
//  « Dans mes livres et chez mes amis », uncapped — where « Tout voir » leads.
//
//  The merged search caps its local section at three so the road to inventaire.io stays above
//  the keyboard (PRD 0012). That cap is a display rule and it must never hide a book, which is
//  the question issue 0075 left open: among a dedicated screen, the inventory list filtered,
//  and an in-place unfold, the owner chose the screen. It is the answer that stays consistent
//  with the remote results — one tap in, one tap back, the field and its suggestions still
//  there when you return — where the filtered list would have dropped the user into another
//  screen without them, and the unfold would have put the second half of the feature back under
//  the keyboard.
//
//  It shows exactly what the section shows, minus the cap: the same books, mine before my
//  friends' and most recently added first inside each group. Not "the same rule reimplemented"
//  — the same call, `InventorySearchRanking.rankItems`, with `noLimit` instead of the default.
//  The rows are `InventoryCell`, so a friend's copy still names its owner and tapping one still
//  opens the copy rather than an abstract edition.
//
//  One `@Query` over every copy on the device rather than two, because the owner is only known
//  once the environment has a user and a `@Query` predicate is built in `init`. Mine and my
//  friends' are told apart where they are ranked, which is where the distinction matters.
//
//  The title is the section's own key: the same answer, so the same name.
//
//  See PRD 0012 and issue 0075.
//

import SwiftData
import SwiftUI

struct InventorySearchAllLocalView: View {
    /// The query this screen answers, carried from the header that pushed it. The search field
    /// is on the screen below, so nothing here can read it back.
    let query: String

    @Environment(UserModel.self) private var userModel

    @Query(sort: \InventoryItem.created, order: .reverse) private var items: [InventoryItem]

    private var rankedItems: [InventoryItem] {
        guard let ownerId = userModel.myUser?._id else { return [] }

        return InventorySearchRanking.rankItems(
            items,
            matching: query,
            ownerId: ownerId,
            limit: InventorySearchRanking.noLimit
        )
        .items
    }

    var body: some View {
        List {
            ForEach(rankedItems) { item in
                NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                    InventoryCell(
                        item: item,
                        filterParameter: item.ownerId == userModel.myUser?._id ? .userInventory : .othersInventory
                    )
                }
                .accessibilityIdentifier("e2e.searchLocalResult")
            }
        }
        .listStyle(.plain)
        .applyListBackground()
        .navigationTitle("inventory.search.local_section")
        .navigationBarTitleDisplayMode(.inline)
    }
}
