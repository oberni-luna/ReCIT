//
//  SearchFriendsSection.swift
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
//  width and spacing. With no friend at all, a paper tag toward Réseau stands in their place;
//  what to draw is `FriendsCarouselState`'s call (issue 0117).
//

import SwiftUI

struct SearchFriendsSection: View {
    /// What to draw — decided by `FriendsCarouselState`, which also caps `items`.
    let state: FriendsCarouselState
    /// My friends' books, most recent first, already cut to what the state shows.
    let items: [InventoryItem]
    /// The invitation's way to Réseau, for a reader with no friend yet.
    let onInvite: () -> Void

    /// The width the row was given, which sets each card's width exactly as « Ranger mes
    /// livres » does — `SortGridMetrics.bookColumnWidth`, three cards and a peek.
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .invitation:
            Section {
                SearchFriendsInvitationTag(onTap: onInvite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .small)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } header: {
                Text("inventory.search.friends_section")
            }
        case .recent(_, let showsSeeAll):
            Section {
                carousel
            } header: {
                header(showsSeeAll: showsSeeAll)
            }
        }
    }

    private var carousel: some View {
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
    }

    /// Same shape as the local section's header (`SearchLocalHeader`): the title, and « Tout
    /// voir » at the trailing edge when the cap hides something.
    private func header(showsSeeAll: Bool) -> some View {
        HStack {
            Text("inventory.search.friends_section")

            Spacer()

            if showsSeeAll {
                NavigationLink(
                    "inventory.search.see_all",
                    value: NavigationDestination.friendsLatestBooks
                )
                .buttonStyle(.plain)
                .foregroundStyle(.foregroundTinted)
                .accessibilityIdentifier("e2e.searchFriends.seeAll")
            }
        }
    }
}
