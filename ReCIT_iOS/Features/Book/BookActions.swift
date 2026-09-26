//
//  BookActions.swift
//  ReCIT_iOS
//
//  The book's actions — file it on an étagère, add it to a list, remove my copy, borrow
//  someone else's, add it to my inventory — written once and carried two ways: as the
//  "…" menu in the book screen's toolbar, and as the long-press menu of every book cell.
//  The two used to be one menu on one screen; a row had nothing, so everything meant
//  opening the book first.
//
//  The modifier owns what the lines lead to — the borrow form, the creation sheet, the
//  delete confirmation — because a `.sheet` placed inside a `Menu`'s content does not
//  present reliably, and a context menu is a `Menu` too.
//

import SwiftUI
import SwiftData
import LBSnackBar

extension View {
    /// Attaches the book's actions for `edition`. `nil` attaches nothing, which is how the
    /// book screen says it has not loaded yet.
    ///
    /// - Parameter onRemoved: Runs once my copy has been deleted on the server — the book
    ///   screen pops there; a row has nothing to do, it disappears on its own.
    func bookActions(
        edition: Edition?,
        placement: ActionsPlacement,
        onRemoved: @escaping () -> Void = {}
    ) -> some View {
        modifier(
            BookActionsModifier(
                edition: edition,
                placement: placement,
                onRemoved: onRemoved
            )
        )
    }
}

struct BookActionsModifier: ViewModifier {
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    let edition: Edition?
    let placement: ActionsPlacement
    let onRemoved: () -> Void

    @State private var borrowFromItem: InventoryItem?
    @State private var showDeleteConfirmation: Bool = false
    /// What the menu asks to create. Held here rather than by the menu: a `.sheet` placed
    /// inside a `Menu`'s content does not present reliably.
    @State private var creationRequest: ContainerCreationRequest?

    func body(content: Content) -> some View {
        placed(content)
            .sheet(item: $borrowFromItem) { item in
                if let owner = item.owner, let me = userModel.myUser {
                    TransactionFormView(
                        transaction: .init(
                            _id: "",
                            _rev: "",
                            item: item,
                            owner: owner,
                            requester: me,
                            type: item.transaction,
                            created: .now,
                            messages: [],
                            state: .requested,
                            actions: [],
                            readStatus: .init(owner: false, requester: true)
                        ),
                        transition: TransactionStateMachine.requestTransition
                    )
                }
            }
            .containerCreationSheet($creationRequest)
            .confirmationDialog(
                "inventory.item.delete_confirm",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("inventory.item.remove_from_inventory", role: .destructive) {
                    Task {
                        await deleteOwnedItem()
                    }
                }
                .accessibilityIdentifier("e2e.book.confirmRemove")
                Button("action.cancel", role: .cancel) { }
            }
    }

    @ViewBuilder
    private func placed(_ content: Content) -> some View {
        switch placement {
        case .toolbar:
            content.toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if let edition {
                        Menu {
                            // Glyphs in the label colour rather than the app's green, and titles
                            // already are: the framework's own menus read that way, and an accent on
                            // the icons alone made every line look like a link. See `foregroundDefault`.
                            menuContent(edition: edition)
                                .tint(.foregroundDefault)
                        } label: {
                            Label("action.more", systemImage: "ellipsis")
                        }
                        .accessibilityIdentifier("e2e.book.menu")
                    }
                }
            }
        case .contextMenu:
            content.contextMenu {
                if let edition {
                    menuContent(edition: edition)
                        .tint(.foregroundDefault)
                }
            }
        }
    }

    /// My copy of this edition, if I have one.
    ///
    /// The `isStillInTheStore` test comes first because the menu is offered on the screens
    /// that do the deleting: `edition.items` can still hold the copy that was just removed,
    /// and `ownerId` is a persisted read that traps on it. See `PersistentModel+StillInTheStore`
    /// and issue 0065.
    private func iOwn(_ edition: Edition) -> InventoryItem? {
        edition.items.first { $0.isStillInTheStore && $0.ownerId == userModel.myUser?._id }
    }

    /// Two menus, one per side of the ownership line: what I can do to my own copy, and what
    /// I can do about someone else's. Nothing carries a colour of its own: a red « Supprimer »
    /// among five black lines shouted, and the confirmation behind it is what actually guards
    /// the deletion.
    @ViewBuilder
    private func menuContent(edition: Edition) -> some View {
        if let myItem = iOwn(edition) {
            // Étagères hold a specific copy, so filing is offered only on mine.
            BookShelfMenu(item: myItem, creationRequest: $creationRequest)
            listMenu(edition: edition)

            Button("inventory.item.remove_from_inventory", systemImage: "trash") {
                showDeleteConfirmation = true
            }
            .accessibilityIdentifier("e2e.book.remove")
        } else {
            let lenders: [InventoryItem] = borrowableItems(edition)
            if !lenders.isEmpty {
                Menu("action.borrow_from", systemImage: "hand.wave") {
                    ForEach(lenders) { item in
                        if let owner = item.owner {
                            Button(owner.username) {
                                borrowFromItem = item
                            }
                        }
                    }
                }
            }

            listMenu(edition: edition)

            Button("action.add_to_inventory", systemImage: "plus") {
                Task {
                    await addToInventory(edition: edition)
                }
            }
            .accessibilityIdentifier("e2e.book.addToInventory")
        }
    }

    /// Listes hold works, not editions. An edition standing behind several works would have to
    /// file them all, which is not what the menu says it does, so it offers nothing there —
    /// including its creation line, which would be as ambiguous as the rest.
    @ViewBuilder
    private func listMenu(edition: Edition) -> some View {
        if edition.workUris.count == 1, let workUri = edition.workUris.first {
            EntityListMenu(
                entityUri: workUri,
                identifier: "e2e.book.addToList",
                creationRequest: $creationRequest
            )
        }
    }

    /// The first five distinct other owners of this edition — the people I could
    /// ask to borrow it from. (ADR 0002 follow-up: the request-to-borrow flow.)
    private func borrowableItems(_ edition: Edition) -> [InventoryItem] {
        var seenOwners: Set<String> = []
        return edition.items
            .filter { $0.isStillInTheStore }
            .filter { $0.ownerId != userModel.myUser?._id && $0.owner != nil && $0.transaction != .inventorying }
            .filter { seenOwners.insert($0.ownerId).inserted }
            .prefix(5)
            .map { $0 }
    }

    /// Removes my copy of the edition after confirmation, then hands over to `onRemoved`.
    ///
    /// Only on success. A failed delete keeps the copy, with the reason in the snack bar.
    @MainActor
    private func deleteOwnedItem() async {
        guard let edition, let item = iOwn(edition) else { return }

        do {
            try await inventoryModel.removeItem(item, modelContext: modelContext)
            snackBar.show {
                SnackBarView(title: String(localized: "inventory.item.deleted"), onDismiss: nil)
            }
            onRemoved()
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }

    @MainActor
    private func addToInventory(edition: Edition) async {
        guard let user = userModel.myUser else {
            snackBar.show { SnackBarView(title: String(localized: "edition.error.no_user"), onDismiss: nil) }
            return
        }

        do {
            _ = try await inventoryModel.postNewItem(
                modelContext: modelContext,
                entityUri: edition.uri,
                transaction: .inventorying,
                visibility: [.friends],
                forUser: user
            )
            snackBar.show { SnackBarView(title: String(localized: "edition.added_to_inventory"), onDismiss: nil) }
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}
