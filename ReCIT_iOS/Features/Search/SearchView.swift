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
    @State private var isLoadingRemote: Bool = false
    @State private var isLoadingLocal: Bool = false
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
            if results.isEmpty {
                Group {
                    if searchText.isEmpty {
                        inspirationnalViewSection
                    } else if isLoadingLocal || isLoadingRemote {
                        loadingResultsCell
                    } else {
                        emptyView
                    }
                }
                .padding(.vertical, 4)
            } else {
                resultListContent
                if isLoadingRemote {
                    loadingMoreResultsCell
                }
            }
        }
        .navigationTitle("nav.search")
        .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "search.placeholder")
        .onChange(of: searchText) { prev, next in
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                isLoadingLocal = true
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled else { return }
                await fetchSearchResults()
            }
        }
    }

    var loadingResultsCell: some View {
        HStack(spacing: 12) {
            ProgressView()
                .frame(width: 36)
                .foregroundStyle(.foregroundTinted)

            Text("searching...")
                .textStyle(.action300)
        }
    }

    var loadingMoreResultsCell: some View {
        HStack(spacing: 12) {
            ProgressView()
                .frame(width: 36)
                .foregroundStyle(.foregroundTinted)

            Text("loading more results...")
                .textStyle(.action300)
        }
    }

    @ViewBuilder
    var emptyView: some View {
        VStack(spacing: .medium) {
            Text("🥲")
                .textStyle(.title200)
            Text("search.empty")
                .textStyle(.action300)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var resultListContent: some View {
        ForEach(results) { result in
            Button {
                onNavigate(result)
            } label: {
                NavigationLink(value: UUID()){
                    SearchResultCell(result: result)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    var inspirationnalViewSection: some View {
        if let user = userModel.myUser {
            Section("search.friends_inventory") {
                InventoryListContent(
                    user: user,
                    searchText: "",
                    filterParameter: .othersInventory,
                    sortParameter: .recent
                )
            }
        }
    }

    @MainActor
    private func fetchSearchResults() async {
        errorMessage = nil
        isLoadingLocal = true
        
        let trimmedQuery: String = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let localResults: [SearchResult] = inventoryModel.searchLocalInventory(query: trimmedQuery, modelContext: modelContext)
        results = localResults

        guard trimmedQuery.count >= 3 else {
            isLoadingLocal = false
            return
        }
        
        isLoadingRemote = true
        do {
            let remoteResults: [SearchResult] = try await inventoryModel.searchEntity(query: trimmedQuery)

            let remoteUris: Set<String> = .init(remoteResults.map(\.uri))
            let uniqueLocalResults: [SearchResult] = localResults.filter { !remoteUris.contains($0.uri) }

            results = uniqueLocalResults + remoteResults
            isLoadingLocal = false
            isLoadingRemote = false
        } catch {
            errorMessage = String(localized: "search.error")
            isLoadingLocal = false
            isLoadingRemote = false
        }
    }
}
