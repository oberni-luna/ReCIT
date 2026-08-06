//
//  ShelfDetailView.swift
//  ReCIT_iOS
//
//  A single étagère opened as a standard list of its books (same cell as the rest of
//  the inventory). Reached by tapping a shelf. See ADR 0003.
//

import SwiftUI
import SwiftData

struct ShelfDetailView: View {
    let shelfId: String
    @Binding var path: NavigationPath

    @Query private var shelves: [Shelf]

    init(shelfId: String, path: Binding<NavigationPath>) {
        self.shelfId = shelfId
        self._path = path
        _shelves = Query(filter: #Predicate { $0._id == shelfId })
    }

    private var shelf: Shelf? { shelves.first }

    private var books: [InventoryItem] {
        (shelf?.items ?? []).sorted { $0.created > $1.created }
    }

    var body: some View {
        List {
            if books.isEmpty {
                Text("Cette étagère est vide")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            } else {
                ForEach(books) { item in
                    NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                        InventoryCell(item: item, filterParameter: .userInventory)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(shelf?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}
