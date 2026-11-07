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
    private static let separatorLeading: CGFloat = DesignSystem.Spacing.sMedium.rawValue

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
            let copies: [(edition: Edition, item: InventoryItem)] = work.editions
                .flatMap { edition in edition.items.map { (edition: edition, item: $0) } }
                .filter { $0.item.isStillInTheStore }
            let myUserId: String? = userModel.myUser?._id
            let friendsCopies: [(edition: Edition, item: InventoryItem)] = copies
                .filter { $0.item.ownerId != myUserId && $0.item.owner != nil }
                .sorted(using: [
                    KeyPathComparator(\.item.owner?.username, comparator: .localizedStandard),
                    KeyPathComparator(\.item._id)
                ])
            let requestRule: TransactionRequestRule = .init(
                copies: copies.map { ($0.item.ownerId, $0.edition.uri) },
                myUserId: myUserId
            )

            Section("list.where_to_find.header") {
                // Keyed on their place rather than on the copy, so a swipe to another work
                // cross-fades each row instead of replacing it.
                ForEach(Array(friendsCopies.enumerated()), id: \.offset) { _, copy in
                    ListCrossFade(id: copy.item._id) {
                        FriendItemRow(
                            copy.item,
                            onOpenFriend: onOpenFriend,
                            onRequest: onRequest
                        )
                        .requestOffered(requestRule.isRequestOffered(forEditionURI: copy.edition.uri))
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in Self.separatorLeading }
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
                        .alignmentGuide(.listRowSeparatorLeading) { _ in Self.separatorLeading }
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
