//
//  BookNetworkPage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// The Fiche livre's Dans le réseau: the other readers' copies — a touch opens their profile, a
/// long press asks for the book —, then my friends' lists holding its work. What its tab counts.
struct BookNetworkPage: View {
    private let layout: FoldingHeaderPageLayout<BookTab>
    private let edition: Edition
    private let onRequest: (InventoryItem) -> Void

    @Binding private var entityDestination: NavigationDestination?

    @Environment(UserModel.self) private var userModel: UserModel

    init(
        _ layout: FoldingHeaderPageLayout<BookTab>,
        edition: Edition,
        entityDestination: Binding<NavigationDestination?>,
        onRequest: @escaping (InventoryItem) -> Void
    ) {
        self.layout = layout
        self.edition = edition
        _entityDestination = entityDestination
        self.onRequest = onRequest
    }

    /// Not when I own a copy of this edition myself.
    private var requestRule: TransactionRequestRule {
        .init(
            copies: edition.items.filter(\.isStillInTheStore).map { ($0.ownerId, edition.uri) },
            myUserId: userModel.myUser?._id
        )
    }

    var body: some View {
        FoldingHeaderPage(layout) {
            BookListEntriesReader(workUris: edition.workUris, myUserId: userModel.myUser?._id) { entries in
                let holdings: BookNetworkHoldings = .init(
                    copies: edition.items,
                    lists: entries,
                    myUserId: userModel.myUser?._id
                )
                if holdings.isEmpty {
                    BookNetworkEmptyState()
                } else {
                    Group {
                        if holdings.copies.isEmpty == false {
                            Section("nav.community") {
                                ForEach(holdings.copies) { item in
                                    FriendItemRow(
                                        item,
                                        onOpenFriend: { entityDestination = .user(user: $0) },
                                        onRequest: onRequest
                                    )
                                    .requestOffered(requestRule.isRequestOffered(forEditionURI: edition.uri))
                                }
                            }
                        }

                        if holdings.lists.isEmpty == false {
                            BookListsSection("book.friends_lists", entries: holdings.lists)
                        }
                    }
                    .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var destination: NavigationDestination?

    BookNetworkPage(
        .init(
            page: .network,
            expandedHeaderHeight: 0,
            headerTop: nil,
            collapse: .init(distance: 0),
            scrollOffset: .init(),
            isFrozen: false
        ),
        edition: .init(uri: "isbn:9782070360024", title: "L'Étranger", lang: "fr", authorNames: []),
        entityDestination: $destination,
        onRequest: { _ in }
    )
}
