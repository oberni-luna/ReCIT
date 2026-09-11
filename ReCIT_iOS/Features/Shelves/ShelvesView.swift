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
    @Environment(SortFlowPresentation.self) private var sortFlow
    @Environment(UserModel.self) private var userModel

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    /// The search that has been sent — the query and the entity types it asked inventaire.io
    /// for. It lives here rather than in the search surface because `.onSubmit(of: .search)`
    /// only reaches the field from the view that carries `.searchable`, or from above it.
    /// Nothing clears it: a query edited afterwards stops matching what was sent, and that is
    /// what takes the screen back out of its results (`SearchPhase`).
    @State private var submission: SearchSuggestion?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let user = userModel.myUser {
                    if user.lastInventorySync == nil {
                        SyncingPlaceholderView()
                    } else {
                        ShelvesContent(
                            user: user,
                            searchText: searchText,
                            submission: $submission,
                            path: $path
                        )
                    }
                } else {
                    SyncingPlaceholderView()
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("nav.inventory")
            // The two ways out of the inventory (PRD 0008). In the navigation bar rather
            // than in a section header: both are about the whole collection, not about the
            // étagères band or the books band, and the two headers already carry actions of
            // their own. "Ranger" waits for a synced inventory behind it — sorting an empty
            // library sorts nothing — while "Scanner" is how the library stops being empty,
            // so it is always there.
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if userModel.myUser?.lastInventorySync != nil {
                        Button("shelves.action.sort", systemImage: "books.vertical.fill") {
                            sortFlow.presentSorting()
                        }
                        .accessibilityIdentifier("e2e.shelves.sort")
                    }
                    Button("shelves.action.scan", systemImage: "barcode.viewfinder") {
                        sortFlow.presentScanning()
                    }
                    .accessibilityIdentifier("e2e.shelves.scan")
                }
            }
            .searchable(text: $searchText)
            // The keyboard's « rechercher » key sends the query against both books and people
            // — the same thing the third suggestion does, and the same value, so the two
            // gestures cannot end up asking inventaire.io for different things. Below three
            // characters it sends nothing: `SearchSuggestion` reads the threshold rather than
            // keeping a second copy of it.
            .onSubmit(of: .search) {
                if let everything = SearchSuggestion.everything(for: searchText) {
                    submission = everything
                }
            }
        }
    }
}
