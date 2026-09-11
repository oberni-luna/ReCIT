//
//  EntityListMenu.swift
//  ReCIT_iOS
//
//  The liste entry of the "…" menus. Listes hold entities by uri — a work, an author — not
//  copies, so this is offered on a book that stands behind a single work and on the work
//  screen itself; the caller resolves the uri and hands it over.
//
//  Every liste the user owns is listed, each line saying whether it files the entity or takes
//  it back out; the shaping is `MembershipMenuEntry`'s and the rendering is `MembershipMenu`'s.
//  The listes come from `@Query` so one created elsewhere shows up without a refresh.
//

import SwiftUI
import SwiftData
import LBSnackBar

struct EntityListMenu: View {
    @Environment(ListModel.self) private var listModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    /// The entity the menu files — a work uri.
    let entityUri: String
    /// Accessibility identifier of the submenu, so the same menu can be told apart on the
    /// screens that carry it.
    let identifier: String
    /// Where the menu writes its demand for a liste that does not exist yet. Given by a screen
    /// that mounts `containerCreationSheet(_:)`; `nil` on one that does not, and the menu then
    /// offers no creation line and hides itself when empty, exactly as before.
    var creationRequest: Binding<ContainerCreationRequest?>?

    @Query(sort: \EntityList.name) private var lists: [EntityList]

    /// Elements are filtered on `isStillInTheStore` first: a liste can hold the element that
    /// was just removed under the open menu. See `PersistentModel+StillInTheStore`.
    private func contains(_ list: EntityList) -> Bool {
        list.elements.contains { $0.isStillInTheStore && $0.uri == entityUri }
    }

    private var entries: [MembershipMenuEntry] {
        MembershipMenuEntry.entries(
            candidates: lists.map { (id: $0._id, name: $0.name) },
            memberIDs: .init(lists.filter(contains).map(\._id))
        )
    }

    /// Writing the demand is all the menu does: the form is mounted by the screen. `nil` when
    /// the screen carries no creation sheet, which is what hides the line.
    private var create: (() -> Void)? {
        guard let creationRequest else { return nil }
        return { creationRequest.wrappedValue = .list(workUri: entityUri) }
    }

    var body: some View {
        MembershipMenu(
            titleKey: "action.list",
            systemImage: "list.clipboard",
            identifier: identifier,
            entries: entries,
            toggle: toggle,
            creationTitleKey: "action.add_to_new_list",
            create: create
        )
    }

    /// Adding is optimistic in the model; removing is not, so it runs in a task of its own and
    /// surfaces its failure through the shared reporter — the same SnackBar either way.
    ///
    /// The confirming SnackBar follows the same line: nothing on the screens carrying this menu
    /// shows the entity's listes, so it is the only thing saying where the book has landed — or
    /// left. It goes up with the local mutation for the optimistic direction, and only once the
    /// server has answered for the removal, which is when the liste actually loses the element.
    private func toggle(_ entry: MembershipMenuEntry) {
        guard let list = lists.first(where: { $0._id == entry.id }) else { return }

        if entry.isMember {
            let name: String = list.name
            Task {
                do {
                    try await listModel.deleteElementsInList(
                        modelContext: modelContext,
                        listId: list._id,
                        elementIds: [entityUri]
                    )
                    show(String(localized: "list.removed_from_named \(name)"))
                } catch {
                    errorReporter.report(error)
                }
            }
        } else {
            listModel.addEntitiesToList(
                modelContext: modelContext,
                list: list,
                entityUris: [entityUri]
            )
            show(String(localized: "list.added_to_named \(list.name)"))
        }
    }

    private func show(_ title: String) {
        snackBar.show {
            SnackBarView(title: title, onDismiss: nil)
        }
    }
}
