//
//  EntityListDetail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import SwiftData

struct EntityListDetail: View {
    let list: EntityList
    @Binding var path: NavigationPath

    @State private var presentEditForm: Bool = false

    var body: some View {
        List {
            Section {
                switch list.type {
                case .author:
                    AuthorListItems(list: list, path: $path)
                case .work:
                    WorkListItems(list: list, path: $path)
                case .publisher:
                    Text("list.empty")
                        .textStyle(.content300)
                }
            }
        }
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
        .applyListBackground()
    }
}

// MARK: - Author items

private struct AuthorListItems: View {
    @EnvironmentObject private var entityModel: EntityModel
    @EnvironmentObject private var listModel: ListModel
    @Environment(\.modelContext) private var modelContext

    let list: EntityList
    @Binding var path: NavigationPath

    @Query private var authors: [Author]
    @State private var isLoading: Bool = true
    @State private var fetchError: Error?

    init(list: EntityList, path: Binding<NavigationPath>) {
        self.list = list
        self._path = path
        let uris: [String] = list.elements.map(\.uri)
        _authors = Query(filter: #Predicate<Author> { author in
            uris.contains(author.uri)
        })
    }

    /// Authors ordered by their position in the list, joined with their list item.
    private var orderedItems: [(EntityListItem, Author)] {
        list.elements.compactMap { item in
            guard let author = authors.first(where: { $0.uri == item.uri }) else { return nil }
            return (item, author)
        }
    }

    var body: some View {
        Group {
            if isLoading && orderedItems.isEmpty {
                Text("list.loading")
            } else if let error = fetchError, orderedItems.isEmpty {
                Text("list.error.loading \(error.localizedDescription)")
                    .textStyle(.content300)
            } else if orderedItems.isEmpty {
                Text("list.empty")
                    .textStyle(.content300)
            } else {
                ForEach(orderedItems, id: \.0._id) { item, author in
                    Button {
                        path.append(NavigationDestination.author(uri: author.uri))
                    } label: {
                        NavigationLink(value: UUID()) {
                            ListItemCellView(listItem: item, entity: author)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("action.delete", systemImage: "trash") {
                            Task {
                                await deleteItem(listItem: item)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await fetchAuthors()
        }
    }

    @MainActor
    private func fetchAuthors() async {
        defer { isLoading = false }
        do {
            _ = try await entityModel.getOrFetchAuthors(
                modelContext: modelContext,
                uris: list.elements.map(\.uri)
            )
        } catch {
            fetchError = error
        }
    }

    @MainActor
    private func deleteItem(listItem: EntityListItem) async {
        do {
            try await listModel.deleteElementsInList(
                modelContext: modelContext,
                listId: list._id,
                elementIds: [listItem.uri]
            )
        } catch {}
    }
}

// MARK: - Work items

private struct WorkListItems: View {
    @EnvironmentObject private var entityModel: EntityModel
    @EnvironmentObject private var listModel: ListModel
    @Environment(\.modelContext) private var modelContext

    let list: EntityList
    @Binding var path: NavigationPath

    @Query private var works: [Work]
    @State private var isLoading: Bool = true
    @State private var fetchError: Error?

    init(list: EntityList, path: Binding<NavigationPath>) {
        self.list = list
        self._path = path
        let uris: [String] = list.elements.map(\.uri)
        _works = Query(filter: #Predicate<Work> { work in
            uris.contains(work.uri)
        })
    }

    /// Works ordered by their position in the list, joined with their list item.
    private var orderedItems: [(EntityListItem, Work)] {
        list.elements.compactMap { item in
            guard let work = works.first(where: { $0.uri == item.uri }) else { return nil }
            return (item, work)
        }
    }

    var body: some View {
        Group {
            if isLoading && orderedItems.isEmpty {
                Text("list.loading")
            } else if let error = fetchError, orderedItems.isEmpty {
                Text("list.error.loading \(error.localizedDescription)")
                    .textStyle(.content300)
            } else if orderedItems.isEmpty {
                Text("list.empty")
                    .textStyle(.content300)
            } else {
                ForEach(orderedItems, id: \.0._id) { item, work in
                    Button {
                        path.append(NavigationDestination.work(uri: work.uri))
                    } label: {
                        NavigationLink(value: UUID()) {
                            ListItemCellView(listItem: item, entity: work)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("action.delete", systemImage: "trash") {
                            Task {
                                await deleteItem(listItem: item)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await fetchWorks()
        }
    }

    @MainActor
    private func fetchWorks() async {
        defer { isLoading = false }
        do {
            _ = try await entityModel.getOrFetchWorks(
                modelContext: modelContext,
                uris: list.elements.map(\.uri)
            )
        } catch {
            fetchError = error
        }
    }

    @MainActor
    private func deleteItem(listItem: EntityListItem) async {
        do {
            try await listModel.deleteElementsInList(
                modelContext: modelContext,
                listId: list._id,
                elementIds: [listItem.uri]
            )
        } catch {}
    }
}

#Preview {
//    EntityListDetail()
}
