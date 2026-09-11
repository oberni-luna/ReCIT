//
//  ReaderSearchView.swift
//  ReCIT_iOS
//
//  Looking somebody up on inventaire.io by their username — frames `N2` (at rest) and `N3`
//  (results) of the « Réseau » pass.
//
//  By username, and by nothing else: `GET /api/search?types=users` is the only reader search
//  the server has. `/users/by-usernames` wants the name exactly, and `/users/nearby` wants a
//  position — a permission, and a screen this feature does not have. So the screen at rest says
//  what it searches, rather than pretending to offer discovery.
//

import SwiftUI
import SwiftData

struct ReaderSearchView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    @Binding var path: NavigationPath

    @State private var query: String = ""
    @State private var results: [User] = []
    @State private var isSearching: Bool = false
    @State private var hasSearched: Bool = false

    var body: some View {
        List {
            if results.isEmpty {
                Section {
                    placeholder
                        .padding(.vertical, .large)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(results) { user in
                        ReaderRowView(user: user) {
                            path.append(NavigationDestination.user(user: user))
                        }
                    }
                } header: {
                    Text("network.search.header")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
        }
        .applyListBackground()
        .navigationTitle("network.add_friends")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: Text("network.search.prompt"))
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .task(id: query) {
            await search()
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if isSearching {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if hasSearched {
            EmptyStateView(
                glyph: "magnifyingglass",
                title: "network.search.no_results",
                message: "network.search.no_results.message \(query)"
            )
        } else {
            EmptyStateView(
                glyph: "magnifyingglass",
                title: "network.search.title",
                message: "network.search.explanation"
            )
        }
    }

    /// Runs on every change of the query, after a pause: `.task(id:)` cancels the previous one,
    /// so a reader typing eight letters makes one request rather than eight.
    private func search() async {
        let trimmedQuery: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            results = []
            hasSearched = false
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(350))
        } catch {
            return
        }

        isSearching = true
        defer { isSearching = false }
        do {
            results = try await userModel.searchReaders(query: trimmedQuery, modelContext: modelContext)
            hasSearched = true
        } catch {
            // Nothing found and nothing claimed: the placeholder says the search came back
            // empty, which is what the reader sees either way, and a failed lookup is not
            // worth a snack bar over a screen whose whole content is the answer.
            results = []
            hasSearched = true
        }
    }
}
