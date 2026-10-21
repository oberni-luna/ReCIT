//
//  InventorySearchFriendsSection.swift
//  ReCIT_iOS
//
//  « Chez mes amis »: a single row of my friends' books, most recently added first — the news
//  from their shelves, shown only while nothing is typed. Once a query stands, my friends'
//  copies are part of the answer, next to mine in the local section, and the carousel leaves.
//
//  It used to stay while typing, shrunk and filtered (the spike of PRD 0020, issue 0115). Going
//  back from three characters to two then removed the local section and left the friends'
//  carousel alone on screen, which read as a mistake: discovery and answer are now two moments.
//
//  The cards are `SortBookCardView`, the ones « Ranger mes livres » files from, at the same
//  width and spacing.
//

import SwiftUI

struct InventorySearchFriendsSection: View {
    let items: [InventoryItem]

    /// The width the row was given, which sets each card's width exactly as « Ranger mes
    /// livres » does — `SortGridMetrics.bookColumnWidth`, three cards and a peek.
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        if !items.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: SortGridMetrics.bookSpacing) {
                        // Not before the width is known: a card laid out at zero has its cover
                        // decoded for a zero-sized frame, and `CachedAsyncImage` never asks again.
                        ForEach(containerWidth > 0 ? items : []) { item in
                            NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                                FriendsCarouselCover(
                                    item: item,
                                    width: SortGridMetrics(containerWidth: containerWidth).bookColumnWidth
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, .medium)
                }
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    containerWidth = width
                }
                .scrollIndicators(.hidden)
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("e2e.searchFriends.carousel")
            } header: {
                Text("inventory.search.friends_section")
            }
        }
    }
}
