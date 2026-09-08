//
//  BookShelfMenu.swift
//  ReCIT_iOS
//
//  The étagère entry of the book screen's "…" menu. Étagères hold items — a specific
//  copy — not editions, so this is only ever built for the copy the current user owns;
//  the caller resolves that and hands it over.
//
//  Every étagère the user owns is listed, each line saying whether it files the copy or
//  takes it off; the shaping is `MembershipMenuEntry`'s and the rendering is
//  `MembershipMenu`'s. The étagères come from `@Query` so a shelf created elsewhere shows
//  up without a refresh. See PRD 0004.
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

    /// The étagères the copy is on, or none at all once the copy has been deleted under the
    /// open menu — `item.shelves` is a read off a model that may have no row left. See
    /// `PersistentModel+StillInTheStore` and issue 0065.
    private var memberIDs: Set<String> {
        guard item.isStillInTheStore else { return [] }
        return .init(item.shelves.map(\._id))
    }

    private var entries: [MembershipMenuEntry] {
        MembershipMenuEntry.entries(
            candidates: shelves.map { (id: $0._id, name: $0.name) },
            memberIDs: memberIDs
        )
    }

    var body: some View {
        MembershipMenu(
            titleKey: "action.shelf",
            systemImage: "books.vertical.fill",
            identifier: "e2e.book.shelf",
            entries: entries,
            toggle: toggle
        )
    }

    /// The entry always names one of `shelves`, since that is what built it.
    private func toggle(_ entry: MembershipMenuEntry) {
        guard let shelf = shelves.first(where: { $0._id == entry.id }) else { return }

        if entry.isMember {
            shelfModel.removeItem(item, from: shelf, modelContext: modelContext)
        } else {
            shelfModel.addItem(item, to: shelf, modelContext: modelContext)
        }
    }
}
