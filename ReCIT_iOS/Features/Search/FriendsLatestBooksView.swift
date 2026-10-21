//
//  FriendsLatestBooksView.swift
//  ReCIT_iOS
//
//  Where « Tout voir » leads from « Chez mes amis »: every book my friends have, most recently
//  added first — the carousel without its cap. Same rows as « Tout voir » from the local section
//  (`SearchAllLocalView`), each naming its owner, and the carousel's own title.
//
//  See PRD 0020 and issue 0117.
//

import SwiftData
import SwiftUI

struct FriendsLatestBooksView: View {
    @Environment(UserModel.self) private var userModel

    @Query(sort: \InventoryItem.created, order: .reverse) private var items: [InventoryItem]

    /// Every copy that is not mine. Filtered here rather than in a `#Predicate`: the owner id is
    /// only known once the view reads `UserModel`, and a `@Query` is built before that.
    private var friendsItems: [InventoryItem] {
        guard let ownerId = userModel.myUser?._id else { return [] }

        return items.filter { $0.isStillInTheStore && $0.ownerId != ownerId }
    }

    var body: some View {
        List {
            ForEach(friendsItems) { item in
                NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                    InventoryCell(item: item, filterParameter: .othersInventory)
                }
                .accessibilityIdentifier("e2e.searchFriends.allResult")
            }
        }
        .listStyle(.plain)
        .applyListBackground()
        .navigationTitle("inventory.search.friends_section")
        .navigationBarTitleDisplayMode(.inline)
    }
}
