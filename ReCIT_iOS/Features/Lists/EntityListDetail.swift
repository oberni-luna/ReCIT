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
    }
}

// MARK: - Author items

private struct AuthorListItems: View {
    @EnvironmentObject private var entityModel: EntityModel
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
    @EnvironmentObject private var listModel: ListModel
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
    @EnvironmentObject private var entityModel: EntityModel
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
    @EnvironmentObject private var listModel: ListModel
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
