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
            // The way into the sorting surface (PRD 0008). In the navigation bar
            // rather than in a section header: it is about the whole collection, not
            // about the étagères band or the books band, and the two headers already
            // carry actions of their own. Shown only once there is a synced
            // inventory behind it — sorting an empty library sorts nothing.
            .toolbar {
                if userModel.myUser?.lastInventorySync != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("shelves.action.sort", systemImage: "arrow.up.arrow.down") {
                            path.append(NavigationDestination.manualSort)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
        }
    }
}
