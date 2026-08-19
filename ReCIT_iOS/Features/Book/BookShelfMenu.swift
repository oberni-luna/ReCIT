//
//  BookShelfMenu.swift
//  ReCIT_iOS
//
//  The étagère entries of the book screen's "..." menu. Étagères hold items — a specific
//  copy — not editions, so this is only ever built for the copy the current user owns;
//  the caller resolves that and hands it over.
//
//  What to show is not decided here: `ShelfMenuOptions` filters and shapes both lists, and
//  this only renders the shapes it gets. They are complements over the user's étagères, so
//  filing is offered for the ones the copy is not on, un-filing for the ones it is, and an
//  empty list produces no entry rather than a dead one. The étagères come from `@Query` so
//  a shelf created elsewhere shows up without a refresh.
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

        // Not destructive and not red: nothing is deleted, the copy stays in the inventory
        // and on any other étagère, so the entry must not read like the one below it that
        // does throw the book away. The icon says "off the shelf", not "trash".
        switch options.remove {
        case .empty:
            EmptyView()
        case .single(let entry):
            Button("action.remove_from_shelf_named \(entry.name)", systemImage: "tray.and.arrow.up") {
                remove(shelfId: entry.id)
            }
        case .submenu(let entries):
            Menu("action.remove_from_shelf", systemImage: "tray.and.arrow.up") {
                ForEach(entries) { entry in
                    Button(entry.name) {
                        remove(shelfId: entry.id)
                    }
                }
            }
        }
    }

    private func add(shelfId: String) {
        guard let shelf = shelves.first(where: { $0._id == shelfId }) else { return }
        shelfModel.addItem(item, to: shelf, modelContext: modelContext)
    }

    /// Both lists are drawn from `shelves`, so the étagère is always among them; a stale
    /// membership pointing elsewhere is filtered out before it can be offered.
    private func remove(shelfId: String) {
        guard let shelf = shelves.first(where: { $0._id == shelfId }) else { return }
        shelfModel.removeItem(item, from: shelf, modelContext: modelContext)
    }
}
