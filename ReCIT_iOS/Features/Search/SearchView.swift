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
    @EnvironmentObject private var searchModel: SearchModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query var latestItems: [InventoryItem]

    @State private var searchText: String = ""
    @State private var remoteResults: [SearchResult] = []
    @State private var isLoadingRemote: Bool = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>? = nil

    let onNavigate: (SearchResult) -> Void

    @State private var isSearchPresented: Bool = true

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isRemoteSectionVisible: Bool {
        return trimmedQuery.count >= 3
    }

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            friendsInventorySection

            if isRemoteSectionVisible {
                remoteResultsSection
            }
        }
        .navigationTitle("nav.search")
        .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "search.placeholder")
        .onChange(of: searchText) { _, next in
            searchTask?.cancel()
            guard !next.isEmpty else {
                remoteResults = []
                return
            }
            searchTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled else { return }
                await fetchSearchResults()
            }
        }
        .applyListBackground()
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
    var friendsInventorySection: some View {
        if let user = userModel.myUser {
            Section("search.friends_inventory") {
                InventoryListContent(
                    user: user,
                    searchText: searchText,
                    filterParameter: .othersInventory,
                    sortParameter: .recent
                )
            }
        }
    }

    @ViewBuilder
    var remoteResultsSection: some View {
        Section(.init("search.remote_results")) {
            if isLoadingRemote {
                loadingMoreResultsCell
            } else if !remoteResults.isEmpty {
                ForEach(remoteResults) { result in
                    Button {
                        onNavigate(result)
                    } label: {
                        NavigationLink(value: UUID()) {
                            SearchResultCell(result: result)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
            } else {
                emptyRemoteResultsCell
            }
        }
    }

    @ViewBuilder
    var emptyRemoteResultsCell: some View {
        VStack {
            Text("search.remote.empty".capitalized)
                .foregroundStyle(.secondary)
                .textStyle(.action200)
        }
    }

    @MainActor
    private func fetchSearchResults() async {
        errorMessage = nil

        if isRemoteSectionVisible {
            isLoadingRemote = true
            do {
                remoteResults = try await searchModel.searchEntity(query: trimmedQuery)
                isLoadingRemote = false
            } catch {
                errorMessage = String(localized: "search.error")
                isLoadingRemote = false
            }
        }
    }
}
