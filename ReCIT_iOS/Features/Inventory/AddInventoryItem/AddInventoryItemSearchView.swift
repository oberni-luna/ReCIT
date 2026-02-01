//
//  AddInventoryItemView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/01/2026.
//

import SwiftUI

struct AddInventoryItemSearchView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchResult: SearchResult?
    @State private var addingItemId: String?
    @State private var path: NavigationPath = .init()

    var body: some View {
        NavigationStack(path: $path) {
            SearchView(onNavigate: { result in
                if let destination = NavigationDestination.destinationForSearchResult(result) {
                    path.append(destination)
                }
            })
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
        }
    }

}

