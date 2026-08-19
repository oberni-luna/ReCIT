//
//  ShelvesContent.swift
//  ReCIT_iOS
//
//  The synced state of the bookshelf: a horizontal, snapping carousel of étagères
//  (A→Z) over a vertical list of all the user's books. Both are `@Query`-driven so
//  they stay reactive across syncs. Focusing the search hides the shelves and shows
//  the flat filtered list. See ADR 0003 / PRD 0001.
//

import SwiftUI
import SwiftData

struct ShelvesContent: View {
    let user: User
    let searchText: String
    @Binding var path: NavigationPath

    @Environment(\.isSearching) private var isSearching
    @Environment(ShelfFocusModel.self) private var focus

    /// Presents the create-shelf form — from the section header's "Ajouter" action or from
    /// the empty-state card, which is why the sheet hangs off the page, not the carousel.
    @State private var isCreatingShelf: Bool = false

    @Query private var shelves: [Shelf]
    @Query private var myItems: [InventoryItem]

    private let horizontalPadding: CGFloat = 12
    private let gutter: CGFloat = 14

    init(user: User, searchText: String, path: Binding<NavigationPath>) {
        self.user = user
        self.searchText = searchText
        self._path = path

        let ownerId: String = user._id
        _shelves = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.name,
            order: .forward
        )
        _myItems = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.created,
            order: .reverse
        )
    }

    var body: some View {
        if isSearching {
            List {
                InventoryListContent(
                    user: user,
                    searchText: searchText,
                    filterParameter: .userInventory,
                    sortParameter: .alphabetical
                )
            }
            .listStyle(.plain)
        } else {
            GeometryReader { geo in
                let cardWidth: CGFloat = geo.size.width * 0.86
                ScrollView {
                    ShelfSectionHeader(
                        title: "Étagères",
                        actionTitle: "Ajouter",
                        action: { isCreatingShelf = true }
                    )
                    .padding(.top, .medium)
                    // One or the other, never both: with no étagère there is nothing to
                    // page through, so the empty shelf stands in place of the carousel.
                    if shelves.isEmpty {
                        ShelfEmptyStateView(width: cardWidth) { isCreatingShelf = true }
                            // Parked where the carousel's first card would be, so the
                            // first real étagère appears exactly here.
                            .padding(.horizontal, horizontalPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        shelvesCarousel(cardWidth: cardWidth)
                    }

                    ShelfSectionHeader(title: "Tous les livres · \(myItems.count)")
                        .padding(.top, .large)
                    allBooksList
                }
                // Frozen while a shelf is being scrubbed, so the slide can't scroll the page.
                .scrollDisabled(focus.isArmed)
                .sheet(isPresented: $isCreatingShelf) {
                    ShelfFormView()
                }
            }
        }
    }

    /// Horizontal, snapping carousel of shelf cards (~86% width, next card peeking).
    /// Nested inside the page's vertical scroll; only this scrolls horizontally.
    private func shelvesCarousel(cardWidth: CGFloat) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: gutter) {
                ForEach(shelves) { shelf in
                    ShelfRowView(shelf: shelf, width: cardWidth, path: $path)
                        .frame(width: cardWidth)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, horizontalPadding)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        // Frozen while a scrub is on, so the slide moves the selection, not the cards.
        .scrollDisabled(focus.isArmed)
    }

    private var allBooksList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(myItems) { item in
                NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                    InventoryCell(item: item, filterParameter: .userInventory)
                        .padding(.horizontal, .medium)
                        .padding(.vertical, .small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider()
                    .padding(.leading, .medium)
            }
        }
    }
}
