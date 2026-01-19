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
                    SearchResultDetailView(result: result)
                }
                .navigationDestination(for: Author.self) { author in
                    Text("Author view for \(author.name)")
                }
                .navigationDestination(for: Work.self) { work in
                    Text("Work view for \(work.title)")
                }
                .navigationDestination(for: Edition.self) { edition in
                    EditionView(edition: edition)
                }
        }
    }

}

