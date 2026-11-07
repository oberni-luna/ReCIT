//
//  ListWhereToFindSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import SwiftData
import SwiftUI

/// « Où trouver ce livre ? » under the work a Liste has selected: my friends' copies of it, in any
/// edition, then a search for it on Recyclivre and on Chez mon libraire. Read from the store
/// alone; absent until the work is in it.
struct ListWhereToFindSection: View {
    private let workURI: String
    private let onOpenFriend: (User) -> Void
    private let onRequest: (InventoryItem) -> Void

    @Environment(UserModel.self) private var userModel: UserModel

    @Query private var works: [Work]

    init(
        workURI: String,
        onOpenFriend: @escaping (User) -> Void,
        onRequest: @escaping (InventoryItem) -> Void
    ) {
        self.workURI = workURI
        self.onOpenFriend = onOpenFriend
        self.onRequest = onRequest
        _works = Query(filter: #Predicate<Work> { $0.uri == workURI })
    }

    var body: some View {
        if let work = works.first {
            // Deleted copies are dropped before `ownerId` is read: a sync can take one away
            // while the list is open. See `PersistentModel+StillInTheStore` and issue 0065.
            let items: [InventoryItem] = work.editions
                .flatMap(\.items)
                .filter(\.isStillInTheStore)
            let myUserId: String? = userModel.myUser?._id
            let friendsItems: [InventoryItem] = items
                .filter { $0.ownerId != myUserId && $0.owner != nil }
                .sorted(using: [
                    KeyPathComparator(\.owner?.username, comparator: .localizedStandard),
                    KeyPathComparator(\._id)
                ])
            let iOwnTheWork: Bool = items.contains { $0.ownerId == myUserId }

            Section("list.where_to_find.header") {
                // Keyed on their place rather than on the copy, so a swipe to another work
                // cross-fades each row instead of replacing it.
                ForEach(Array(friendsItems.enumerated()), id: \.offset) { _, item in
                    ListCrossFade(id: item._id) {
                        FriendItemRow(
                            item,
                            onOpenFriend: onOpenFriend,
                            onRequest: onRequest
                        )
                        .requestOffered(iOwnTheWork == false)
                    }
                }

                ForEach(Bookshop.allCases, id: \.self) { bookshop in
                    if let url = bookshop.searchURL(title: work.title, authorName: work.authors.first?.name) {
                        ExternalLinkRow(
                            bookshop.linkTitle,
                            subtitle: bookshop.linkSubtitle,
                            logo: bookshop.logo,
                            destination: url
                        )
                        .accessibilityIdentifier(bookshop.linkAccessibilityID)
                    }
                }
            }
        }
    }
}

#Preview("Two friends own it", traits: .modifier(FriendItemsPreviewStore())) {
    NavigationStack {
        DesignSystem.FormList {
            ListWhereToFindSection(
                workURI: FriendItemsPreviewStore.workURI,
                onOpenFriend: { _ in },
                onRequest: { _ in }
            )
        }
    }
}
