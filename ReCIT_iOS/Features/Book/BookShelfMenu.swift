//
//  BookShelfMenu.swift
//  ReCIT_iOS
//
//  The étagère entries of the book screen's "..." menu. Étagères hold items — a specific
//  copy — not editions, so this is only ever built for the copy the current user owns;
//  the caller resolves that and hands it over.
//
//  What to show is not decided here: `ShelfMenuOptions` filters and shapes the lists, and
//  this only renders the shape it gets, so a shelf the book already sits on is never
//  offered and an empty list produces no entry rather than a dead one. The étagères come
//  from `@Query` so a shelf created elsewhere shows up without a refresh.
//  See PRD 0004.
//

import SwiftUI
import SwiftData

struct BookShelfMenu: View {
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(\.modelContext) private var modelContext

    /// The current user's own copy of the book.
    let item: InventoryItem

    @Query private var shelves: [Shelf]

    init(item: InventoryItem) {
        self.item = item

        let ownerId: String = item.ownerId
        _shelves = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.name,
            order: .forward
        )
    }

    private var options: ShelfMenuOptions {
        .init(
            userShelves: shelves.map { .init(id: $0._id, name: $0.name) },
            itemShelves: item.shelves.map { .init(id: $0._id, name: $0.name) }
        )
    }

    var body: some View {
        switch options.add {
        case .empty:
            EmptyView()
        case .single(let entry):
            Button("action.add_to_shelf_named \(entry.name)", systemImage: "books.vertical") {
                add(shelfId: entry.id)
            }
        case .submenu(let entries):
            Menu("action.add_to_shelf", systemImage: "books.vertical") {
                ForEach(entries) { entry in
                    Button(entry.name) {
                        add(shelfId: entry.id)
                    }
                }
            }
        }
    }

    private func add(shelfId: String) {
        guard let shelf = shelves.first(where: { $0._id == shelfId }) else { return }
        shelfModel.addItem(item, to: shelf, modelContext: modelContext)
    }
}
