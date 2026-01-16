//
//  AddInventoryItemView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var results: [SearchResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var addingItemId: String?

    let user: User

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }

                ForEach(results) { result in
                    HStack(alignment: .top, spacing: 12) {
                        NavigationLink {
                            SearchResultDetailView(result: result)
                        } label: {
                            SearchResultCell(result: result)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher une édition")
            .task(id: searchText) {
                await fetchSearchResults()
            }
        }
    }

    @MainActor
    private func fetchSearchResults() async {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            results = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            results = try await inventoryModel.searchEditions(query: trimmedQuery)
        } catch {
            errorMessage = "Impossible de récupérer les résultats."
        }
        isLoading = false
    }
}
