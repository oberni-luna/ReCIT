//
//  AddInventoryItemView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query var latestItems: [InventoryItem]

    @State private var searchText: String = ""
    @State private var results: [SearchResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var addingItemId: String?
    @State private var searchTask: Task<Void, Never>? = nil

    let onNavigate: (SearchResult) -> Void

    @State private var isSearchPresented: Bool = true

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
                            inspirationnalViewContent
                        } else {
                            emptyView
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    resultListContent
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Rechercher une édition")
        .onChange(of: searchText) { prev, next in
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                guard !Task.isCancelled else { return }
                await fetchSearchResults()
            }
        }
    }

    @ViewBuilder
    var emptyView: some View {
        Text("No search results")
    }

    @ViewBuilder
    var resultListContent: some View {
        ForEach(results) { result in
            Button {
                onNavigate(result)
            } label: {
                SearchResultCell(result: result)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    var inspirationnalViewContent: some View {
        if let user = userModel.myUser {
            InventoryListContent(
                user: user,
                searchText: "",
                filterParameter: .othersInventory,
                sortParameter: .alphabetical
            )
        }
    }

    @MainActor
    private func fetchSearchResults() async {
        isLoading = true
        errorMessage = nil

        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 3 else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        do {
            results = try await inventoryModel.searchEntity(query: trimmedQuery)
            isLoading = false
        } catch {
            errorMessage = "Impossible de récupérer les résultats."
            isLoading = false
        }
    }
}
