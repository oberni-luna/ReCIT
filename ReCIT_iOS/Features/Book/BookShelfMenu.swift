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
//  A last line creates an étagère instead of toggling one, so the submenu is there even when
//  the user owns none — the rule itself lives in `MembershipMenu`, written once for both
//  carriers. The line only appears on a screen that mounts `containerCreationSheet(_:)` and
//  hands its binding over, because a `.sheet` inside a `Menu`'s content does not present
//  reliably. See PRD 0014.
//

import SwiftUI
import SwiftData

struct BookShelfMenu: View {
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(\.modelContext) private var modelContext

    /// The current user's own copy of the book.
    let item: InventoryItem

    /// Where the menu writes its demand for an étagère that does not exist yet. Given by a
    /// screen that mounts `containerCreationSheet(_:)`; `nil` on one that does not, and the
    /// menu then offers no creation line and hides itself when empty, exactly as before.
    private let creationRequest: Binding<ContainerCreationRequest?>?

    @Query private var shelves: [Shelf]

    init(
        item: InventoryItem,
        creationRequest: Binding<ContainerCreationRequest?>? = nil
    ) {
        self.item = item
        self.creationRequest = creationRequest

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

    /// Writing the demand is all the menu does: the form is mounted by the screen. `nil` when
    /// the screen carries no creation sheet, which is what hides the line — and `nil` too once
    /// the copy has gone, since there would be nothing left to file. The id is read here,
    /// under the same guard as `memberIDs`, so the closure carries a `String` and never a
    /// model that may have been invalidated by the time it runs.
    private var create: (() -> Void)? {
        guard let creationRequest, item.isStillInTheStore else { return nil }
        let itemID: String = item._id
        return { creationRequest.wrappedValue = .shelf(itemID: itemID) }
    }

    var body: some View {
        MembershipMenu(
            titleKey: "action.shelf",
            systemImage: "books.vertical.fill",
            identifier: "e2e.book.shelf",
            entries: entries,
            toggle: toggle,
            creationTitleKey: "action.add_to_new_shelf",
            create: create
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
