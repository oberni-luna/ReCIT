//
//  InventoryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import SwiftUI
import SwiftData

struct MyInventoryView: View {
    @Environment(UserModel.self) private var userModel

    @State var searchText: String = ""
    @State var path: NavigationPath = .init()
    @State private var isAddItemPresented: Bool = false
    @State private var isScanItemPresented: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            if let user = userModel.myUser {
                Group {
                    if user.lastInventorySync == nil {
                        SyncingPlaceholderView()
                    } else {
                        List {
                            Section(header: Text("nav.inventory")) { }
                            InventoryListContent(
                                user: user,
                                searchText: searchText,
                                filterParameter: .userInventory,
                                sortParameter: .alphabetical
                            )
                        }
                        .listStyle(.plain)
                        .searchable(text: $searchText)
                    }
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destination.viewForDestination($path)
                }
                .navigationTitle("nav.inventory")
                .controlGroupStyle(.palette)
            } else {
                SyncingPlaceholderView()
                    .navigationTitle("nav.inventory")
            }
        }
    }
}

#Preview {
    MyInventoryView()
}
