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
            return allLists.filter { $0.name.localizedStandardContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if syncStatus.shouldShowPlaceholder(.lists) {
                    SyncingPlaceholderView()
                } else if allLists.isEmpty && searchText.isEmpty {
                    ListsEmptyStateView {
                        showNewListModal = true
                    }
                } else {
                    List {
                        ForEach(filteredLists) { list in
                            NavigationLink(value: NavigationDestination.entityList(id: list._id)) {
                                ListRowView(list: list)
                                    .swipeActions {
                                        Button("action.delete", systemImage: "trash") {
                                            Task {
                                                try? await listModel.deleteList(modelContext: modelContext, list: list)
                                            }
                                        }
                                        .tint(.red)
                                    }
                            }
                            .accessibilityIdentifier("e2e.listRow")
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
                    .accessibilityIdentifier("e2e.lists.add")
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
