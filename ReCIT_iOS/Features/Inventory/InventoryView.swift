//
//  MyInventoryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @EnvironmentObject private var userModel: UserModel
    @Query(sort: \InventoryItem.edition?.title) var allItems: [InventoryItem]

    @State private var searchText: String = ""
    @State var path: NavigationPath = .init()
    @State private var isAddItemPresented: Bool = false
    @State private var isScanItemPresented: Bool = false

    let user: User

    init(user: User) {
        self.user = user
        let userId = user._id
        _allItems = Query(filter: #Predicate<InventoryItem> { item in
            item.ownerId == userId
        }, sort: [SortDescriptor(\InventoryItem.edition?.title)])
    }

    var filteredItems: [InventoryItem] {
        if searchText.isEmpty {
            return allItems
        } else {
            let filteredItems = allItems.compactMap { item in
                let titleContainQuery = item.edition?.title.range(of: searchText, options: .caseInsensitive) != nil

                let idContainQuery = item._id.range(of: searchText, options: .caseInsensitive) != nil

                let authorContainQuery = item.edition?.authorNames.joined().range(of: searchText, options: .caseInsensitive) != nil

                return titleContainQuery || idContainQuery || authorContainQuery ? item : nil
            }
            return filteredItems
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(filteredItems) { item in
                    Button {
                        path.append(item)
                    } label : {
                        InventoryCell(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationDestination(for: InventoryItem.self) { item in
                InventoryItemDetailView(item: item, path: $path)
            }
            .navigationDestination(for: EntityDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("📚 Inventory")
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Scan", systemImage: "barcode.viewfinder") {
                        isScanItemPresented = true
                    }
                    Button("Search", systemImage: "plus") {
                        isAddItemPresented = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
            }
            .controlGroupStyle(.palette)
            .listStyle(.plain)
            .searchable(text: $searchText)
            .sheet(isPresented: $isAddItemPresented) {
                AddInventoryItemSearchView()
            }
            .sheet(isPresented: $isScanItemPresented) {
                AddInventoryItemScanView()
            }
        }
    }
}

#Preview {
//    MyInventoryView()
}
