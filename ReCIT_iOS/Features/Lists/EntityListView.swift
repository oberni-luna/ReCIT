//
//  MyInventoryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import SwiftUI
import SwiftData

struct EntityListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(ListModel.self) var listModel
    @Environment(SyncStatusStore.self) private var syncStatus
    @Query(sort: \EntityList.name) var allLists: [EntityList]

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    @State private var showNewListModal: Bool = false

    var filteredLists: [EntityList] {
        if searchText.isEmpty {
            return allLists
        } else {
            let filteredItems = allLists.compactMap { list in
                let nameContainQuery = list.name.range(of: searchText, options: .caseInsensitive) != nil

                return nameContainQuery ? list : nil
            }
            return filteredItems
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if syncStatus.shouldShowPlaceholder(.lists) {
                    SyncingPlaceholderView()
                } else {
                    List {
                        ForEach(filteredLists) { list in
                            NavigationLink(value: NavigationDestination.entityList(id: list._id)) {
                                VStack(alignment: .leading) {
                                    Text(list.name)
                                        .textStyle(.content400Bold)

                                    Text(list.explanation)
                                        .textStyle(.content300)
                                        .foregroundStyle(.secondary)
                                }
                                .swipeActions {
                                    Button("action.delete", systemImage: "trash") {
                                        Task {
                                            try? await listModel.deleteList(modelContext: modelContext, list: list)
                                        }
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("nav.lists")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.add", systemImage: "plus") {
                        showNewListModal = true
                    }
                }
            }
            .searchable(text: $searchText)
            .sheet(isPresented: $showNewListModal) {
                ListFormView()
            }
            .applyListBackground()
        }
    }
}

#Preview {
//    MyInventoryView()
}
