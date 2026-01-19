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

    @Binding var path: NavigationPath

    var body: some View {
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
            } else {
                if results.isEmpty {
                    Group {
                        if searchText.isEmpty {
                            inspirationnalView
                        } else {
                            emptyView
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                ForEach(results) { result in
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            path.append(result)
                        } label: {
                            SearchResultCell(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Rechercher une édition")
        .task(id: searchText) {
            await fetchSearchResults()
        }
    }

    @ViewBuilder
    var emptyView: some View {
        Text("No search results")
    }

    @ViewBuilder
    var inspirationnalView: some View {
        Text("You can search for anything, really!")
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
        defer {
            isLoading = false
        }
        do {
            results = try await inventoryModel.searchEntity(query: trimmedQuery)
        } catch {
            errorMessage = "Impossible de récupérer les résultats."
        }
    }
}
