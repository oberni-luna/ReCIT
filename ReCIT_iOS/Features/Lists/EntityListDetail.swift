//
//  EntityListDetail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import SwiftData

struct EntityListDetail: View {
    let listId: String
    @Binding var path: NavigationPath

    @Query private var matchingLists: [EntityList]
    @State private var presentEditForm: Bool = false

    init(listId: String, path: Binding<NavigationPath>) {
        self.listId = listId
        self._path = path
        _matchingLists = Query(filter: #Predicate<EntityList> { $0._id == listId })
    }

    private var list: EntityList? { matchingLists.first }

    /// Leaves when the list this screen is about stops existing.
    ///
    /// Deleting a list used to drop this screen into its own not-found branch, which draws
    /// `ContentUnavailableView("list.empty")` — so the same screen meant both "this list holds
    /// nothing" and "this list is gone", and the user was left looking at the remains of what
    /// they had just deleted until they pressed back.
    ///
    /// Keyed on the transition rather than on the current value, which is what tells a deletion
    /// apart from the list simply not having synced yet: a screen opened before the first sync
    /// starts empty and must wait, a screen whose list disappears under it must leave.
    private func popIfTheListIsGone(wasMissing: Bool, isMissing: Bool) {
        guard isMissing, !wasMissing, !path.isEmpty else { return }

        path.removeLast()
    }

    var body: some View {
        Group {
            if let list {
                List {
                    Section {
                        switch list.type {
                        case .author:
                            AuthorListItems(listId: listId, path: $path)
                        case .work:
                            WorkListItems(listId: listId, path: $path)
                        case .publisher:
                            Text("list.empty")
                                .textStyle(.content300)
                        }
                    }
                }
                .navigationTitle(list.name)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("action.edit", systemImage: "pencil") {
                            presentEditForm = true
                        }
                    }
                }
                .sheet(isPresented: $presentEditForm) {
                    ListFormView(list: list)
                }
            } else {
                ContentUnavailableView(
                    "list.empty",
                    systemImage: "list.bullet.rectangle"
                )
            }
        }
        .applyListBackground()
        .onChange(of: matchingLists.isEmpty, popIfTheListIsGone)
    }
}

// MARK: - Author items

private struct AuthorListItems: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(\.modelContext) private var modelContext

    let listId: String
    @Binding var path: NavigationPath

    @Query private var items: [EntityListItem]

    init(listId: String, path: Binding<NavigationPath>) {
        self.listId = listId
        self._path = path
        _items = Query(
            filter: #Predicate<EntityListItem> { item in
                item.list?._id == listId
            },
            sort: \EntityListItem.ordinal
        )
    }

    var body: some View {
        Group {
            if items.isEmpty {
                Text("list.empty")
                    .textStyle(.content300)
            } else {
                ForEach(items, id: \._id) { item in
                    AuthorListItemRow(listItem: item, listId: listId, path: $path)
                }
            }
        }
        .task(id: items.map(\.uri)) {
            _ = try? await entityModel.getOrFetchAuthors(
                modelContext: modelContext,
                uris: items.map(\.uri)
            )
        }
    }
}

private struct AuthorListItemRow: View {
    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext

    let listItem: EntityListItem
    let listId: String
    @Binding var path: NavigationPath

    @Query private var authors: [Author]

    init(listItem: EntityListItem, listId: String, path: Binding<NavigationPath>) {
        self.listItem = listItem
        self.listId = listId
        self._path = path
        let uri: String = listItem.uri
        _authors = Query(filter: #Predicate<Author> { $0.uri == uri })
    }

    var body: some View {
        if let author = authors.first {
            Button {
                path.append(NavigationDestination.author(uri: author.uri))
            } label: {
                NavigationLink(value: UUID()) {
                    ListItemCellView(listItem: listItem, entity: author)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e.listItemRow")
            .swipeActions(edge: .trailing) {
                Button("action.delete", systemImage: "trash") {
                    Task {
                        try? await listModel.deleteElementsInList(
                            modelContext: modelContext,
                            listId: listId,
                            elementIds: [listItem.uri]
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Work items

private struct WorkListItems: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(\.modelContext) private var modelContext

    let listId: String
    @Binding var path: NavigationPath

    @Query private var items: [EntityListItem]

    init(listId: String, path: Binding<NavigationPath>) {
        self.listId = listId
        self._path = path
        _items = Query(
            filter: #Predicate<EntityListItem> { item in
                item.list?._id == listId
            },
            sort: \EntityListItem.ordinal
        )
    }

    var body: some View {
        Group {
            if items.isEmpty {
                Text("list.empty")
                    .textStyle(.content300)
            } else {
                ForEach(items, id: \._id) { item in
                    WorkListItemRow(listItem: item, listId: listId, path: $path)
                }
            }
        }
        .task(id: items.map(\.uri)) {
            _ = try? await entityModel.getOrFetchWorks(
                modelContext: modelContext,
                uris: items.map(\.uri)
            )
        }
    }
}

private struct WorkListItemRow: View {
    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext

    let listItem: EntityListItem
    let listId: String
    @Binding var path: NavigationPath

    @Query private var works: [Work]

    init(listItem: EntityListItem, listId: String, path: Binding<NavigationPath>) {
        self.listItem = listItem
        self.listId = listId
        self._path = path
        let uri: String = listItem.uri
        _works = Query(filter: #Predicate<Work> { $0.uri == uri })
    }

    var body: some View {
        if let work = works.first {
            Button {
                path.append(NavigationDestination.work(uri: work.uri))
            } label: {
                NavigationLink(value: UUID()) {
                    ListItemCellView(listItem: listItem, entity: work)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e.listItemRow")
            .swipeActions(edge: .trailing) {
                Button("action.delete", systemImage: "trash") {
                    Task {
                        try? await listModel.deleteElementsInList(
                            modelContext: modelContext,
                            listId: listId,
                            elementIds: [listItem.uri]
                        )
                    }
                }
            }
        }
    }
}

#Preview {
//    EntityListDetail()
}
