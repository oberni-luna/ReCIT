//
//  InventoryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import SwiftUI
import SwiftData

struct MyInventoryView: View {
    @EnvironmentObject private var userModel: UserModel

    @State var searchText: String = ""
    @State var path: NavigationPath = .init()
    @State private var isAddItemPresented: Bool = false
    @State private var isScanItemPresented: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            if let user = userModel.myUser {
                List {
                    InventoryListContent(
                        user: user,
                        searchText: searchText,
                        filterParameter: .userInventory,
                        sortParameter: .alphabetical
                    )
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destination.viewForDestination($path)
                }
                .navigationTitle("📚 Inventory")
                .controlGroupStyle(.palette)
                .listStyle(.plain)
                .searchable(text: $searchText)
            }
        }
    }
}

#Preview {
    MyInventoryView()
}
