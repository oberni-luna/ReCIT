//
//  ShelvesContent.swift
//  ReCIT_iOS
//
//  The synced state of the bookshelf: a 2-column grid of étagères (A→Z) over a list
//  of all the user's books. Both are `@Query`-driven so they stay reactive across
//  syncs. Focusing the search hides the shelves and shows the flat filtered list.
//  Laid out in a ScrollView (not a List) so the painted shelf cells keep a stable,
//  deterministic size. See ADR 0003.
//

import SwiftUI
import SwiftData

struct ShelvesContent: View {
    let user: User
    let searchText: String
    @Binding var path: NavigationPath

    @Environment(\.isSearching) private var isSearching

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
                let cellWidth: CGFloat = (geo.size.width - horizontalPadding * 2 - gutter) / 2
                ScrollView {
                    sectionTitle("Étagères")
                        .padding(.top, .medium)
                    shelvesGrid(cellWidth: cellWidth)

                    sectionTitle("Tous les livres · \(myItems.count)")
                        .padding(.top, .large)
                    allBooksList
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .textStyle(.action200)
            .foregroundStyle(.foregroundDefault)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .medium)
            .padding(.bottom, .small)
    }

    private func shelvesGrid(cellWidth: CGFloat) -> some View {
        let columns: [GridItem] = [
            GridItem(.fixed(cellWidth), spacing: gutter),
            GridItem(.fixed(cellWidth), spacing: gutter)
        ]
        return LazyVGrid(columns: columns, alignment: .center, spacing: 24) {
            ForEach(shelves) { shelf in
                ShelfRowView(shelf: shelf, width: cellWidth, path: $path)
            }
        }
        .padding(.horizontal, horizontalPadding)
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
