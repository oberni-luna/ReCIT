//
//  ShelvesView.swift
//  ReCIT_iOS
//
//  Inventory tab root: the bookshelf. Shows the user's étagères as a 2-up grid with
//  a "sans étagère" list below. When the user searches, it falls back to the flat
//  filtered inventory list. Replaces MyInventoryView. See ADR 0003.
//

import SwiftUI

struct ShelvesView: View {
    @Environment(UserModel.self) private var userModel

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let user = userModel.myUser {
                    if user.lastInventorySync == nil {
                        SyncingPlaceholderView()
                    } else {
                        ShelvesContent(user: user, searchText: searchText, path: $path)
                    }
                } else {
                    SyncingPlaceholderView()
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("nav.inventory")
            .searchable(text: $searchText)
        }
    }
}
