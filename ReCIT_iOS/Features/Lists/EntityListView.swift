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
    @Environment(UserModel.self) private var userModel
    @Query private var storedLists: [EntityList]
    @Query private var users: [User]

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    @State private var showNewListModal: Bool = false

    /// Everything there is to show, search aside: what decides the empty screen and the headers.
    private var allSections: ListsTabSections {
        sections(matching: "")
    }

    private var filteredSections: ListsTabSections {
        sections(matching: searchText)
    }

    private func sections(matching text: String) -> ListsTabSections {
        .init(
            lists: storedLists,
            myUserId: userModel.myUser?._id,
            friends: users.filter { $0.relation == .friend },
            searchText: text
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if syncStatus.shouldShowPlaceholder(.lists) {
                    SyncingPlaceholderView()
                } else if allSections.isEmpty && searchText.isEmpty {
                    ListsEmptyStateView {
                        showNewListModal = true
                    }
                } else {
                    ListsTabList(
                        sections: filteredSections,
                        showsHeaders: !allSections.network.isEmpty,
                        isSearching: !searchText.isEmpty,
                        onCreate: { showNewListModal = true },
                        onDelete: { list in
                            Task {
                                try? await listModel.deleteList(modelContext: modelContext, list: list)
                            }
                        }
                    )
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("nav.lists")
            .toolbar {
                ProfileToolbarItem()
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
            .applyListBackground(.backgroundGrouped)
        }
    }
}

#Preview {
//    MyInventoryView()
}
