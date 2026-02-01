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
    @EnvironmentObject var listModel: ListModel
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
            List {
                ForEach(filteredLists) { list in
                    NavigationLink(value: list) {
                        VStack(alignment: .leading) {
                            Text(list.name)
                                .font(.headline)
                        }
                        .swipeActions {
                            Button("Delete", systemImage: "trash") {
                                Task {
                                    try? await listModel.deleteList(modelContext: modelContext, list: list)
                                }
                            }
                            .tint(.red)
                        }
                    }
                }
            }
            .navigationDestination(for: EntityList.self) { list in
                EntityListDetail(list: list, path: $path)
                    .navigationTitle(list.name)
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("📋 Lists")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("add", systemImage: "plus") {
                        showNewListModal = true
                    }
                }
            }
//            .listStyle(.plain)
            .searchable(text: $searchText)
            .sheet(isPresented: $showNewListModal) {
                ListFormView()
            }
        }
    }
}

#Preview {
//    MyInventoryView()
}
