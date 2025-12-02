//
//  MyInventoryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Query(sort: \InventoryItem.edition?.title) var allItems: [InventoryItem]

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    var filteredItems: [InventoryItem] {
        if searchText.isEmpty {
            return allItems
        } else {
            let filteredItems = allItems.compactMap { item in
                let titleContainQuery = item.edition?.title.range(of: searchText, options: .caseInsensitive) != nil

                let idContainQuery = item._id.range(of: searchText, options: .caseInsensitive) != nil

                let authorContainQuery = item.edition?.authors.joined().range(of: searchText, options: .caseInsensitive) != nil

                return titleContainQuery || idContainQuery || authorContainQuery ? item : nil
            }
            return filteredItems
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { item in
                    NavigationLink(value: item) {
                        InventoryCell(item: item)
                    }
                }
            }
            .navigationDestination(for: InventoryItem.self) { item in
                InventoryItemDetailView(item: item)
            }
            .navigationTitle("📚 Inventory")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("add", systemImage: "plus") {
                        //
                    }
                }
//                ToolbarItem(placement: .topBarLeading) {
//                    EditButton()
//                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
        }
    }
}

#Preview {
//    MyInventoryView()
}
