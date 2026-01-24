//
//  AddInventoryItemView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/01/2026.
//

import SwiftUI

struct AddInventoryItemView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchResult: SearchResult?
    @State private var addingItemId: String?
    @State private var path: NavigationPath = .init()

    var body: some View {
        NavigationStack(path: $path) {
            SearchView(path: $path)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                }
                .navigationDestination(for: SearchResult.self) { result in
                    switch result.type {
                    case .humans:
                        AuthorDetailView(authorUri: result.uri, path: $path)
                    case .works:
                        WorkDetailView(workUri: result.uri, path: $path)
                    default:
                        SearchResultDetailView(result: result)
                    }
                }
                .navigationDestination(for: EntityDestination.self) { destination in
                    switch destination {
                    case .author(let uri):
                        AuthorDetailView(authorUri: uri, path: $path)
                    case .work(let uri):
                        WorkDetailView(workUri: uri, path: $path)
                    }
                }
                .navigationDestination(for: Edition.self) { edition in
                    EditionDetailView(edition: edition, path: $path)
                }
        }
    }

}

