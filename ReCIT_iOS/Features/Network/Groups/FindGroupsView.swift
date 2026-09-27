//
//  FindGroupsView.swift
//  ReCIT_iOS
//
//  Looking a group up by name — frame `A4`. Built like `ReaderSearchView`: a field always on
//  screen, a pause before each request, the server's ranking kept.
//
//  **No « Rejoindre » in the row**, where the maquette draws one. The search answers a name and a
//  description, and nothing about whether the group is open: a button here could not say whether
//  it lets you in or only asks. The row opens the group, whose screen has read the document and
//  offers the right one.
//

import SwiftUI

struct FindGroupsView: View {
    @Environment(GroupModel.self) private var groupModel

    @Binding var path: NavigationPath

    @State private var query: String = ""
    @State private var results: [GroupSearchResult] = []
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
                    ForEach(results) { result in
                        NavigationLink(value: NavigationDestination.group(id: result.id)) {
                            GroupRowView(
                                cell: .init(result: result),
                                role: groupModel.group(id: result.id)?.role(of: groupModel.myUserId)
                            )
                        }
                    }
                } header: {
                    Text("groups.search.header")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                } footer: {
                    GroupNote("groups.search.footer")
                }
            }
        }
        .applyListBackground()
        .navigationTitle("groups.find")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("groups.search.prompt")
        )
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .autocorrectionDisabled()
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
                title: "groups.search.no_results",
                message: "groups.search.no_results.message \(query)"
            )
        } else {
            EmptyStateView(
                glyph: "magnifyingglass",
                title: "groups.search.title",
                message: "groups.search.explanation"
            )
        }
    }

    /// `.task(id:)` cancels the previous run, so eight letters typed make one request.
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
            results = try await groupModel.searchGroups(query: trimmedQuery)
        } catch {
            results = []
        }
        hasSearched = true
    }
}
