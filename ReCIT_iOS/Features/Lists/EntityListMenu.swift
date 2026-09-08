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

struct EntityListMenu: View {
    @Environment(ListModel.self) private var listModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.modelContext) private var modelContext

    /// The entity the menu files — a work uri.
    let entityUri: String
    /// Accessibility identifier of the submenu, so the same menu can be told apart on the
    /// screens that carry it.
    let identifier: String

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

    var body: some View {
        MembershipMenu(
            titleKey: "action.list",
            systemImage: "list.clipboard",
            identifier: identifier,
            entries: entries,
            toggle: toggle
        )
    }

    /// Adding is optimistic in the model; removing is not, so it runs in a task of its own and
    /// surfaces its failure through the shared reporter — the same SnackBar either way.
    private func toggle(_ entry: MembershipMenuEntry) {
        guard let list = lists.first(where: { $0._id == entry.id }) else { return }

        if entry.isMember {
            Task {
                do {
                    try await listModel.deleteElementsInList(
                        modelContext: modelContext,
                        listId: list._id,
                        elementIds: [entityUri]
                    )
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
        }
    }
}
