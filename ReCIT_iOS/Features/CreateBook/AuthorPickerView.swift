//
//  AuthorPickerView.swift
//  ReCIT_iOS
//
//  Choosing the author of a book being created — existing ones first, creating one last.
//
//  The duplicate author is the one piece of damage a contributor of good faith can do: two
//  « Ursula K. Le Guin » on inventaire.io split her bibliography in half, and only a human
//  with merge rights can put it back together. So the screen is built to make the existing
//  answer the easy one: the search runs while you type, each result carries what tells two
//  namesakes apart, and the « create » row sits underneath them all.
//
//  The search is `SearchModel`'s, restricted to people. `resolve` reconciles a finished entry;
//  it does not search as you type, and asking it to would be a second search with different
//  results.
//
//  See PRD 0015.
//

import SwiftUI

struct AuthorPickerView: View {
    @Environment(SearchModel.self) private var searchModel
    @Environment(\.dismiss) private var dismiss

    @Binding var draft: NewBookDraft

    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    @State private var hasSearched: Bool = false

    /// Long enough that typing a name does not fire a request per letter, short enough that
    /// the list feels like it is following the hand.
    private static let debounce: Duration = .milliseconds(300)

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        List {
            if results.isEmpty == false {
                Section {
                    ForEach(results) { result in
                        Button {
                            choose(result)
                        } label: {
                            AuthorPickerRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("create_book.author.existing")
                } footer: {
                    Text("create_book.author.why_existing")
                }
            }

            if trimmedQuery.isEmpty == false {
                Section {
                    Button {
                        createAuthor()
                    } label: {
                        Label("create_book.author.create \(trimmedQuery)", systemImage: "plus")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundTinted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("e2e.createBook.author.create")
                } footer: {
                    if hasSearched, results.isEmpty {
                        Text("create_book.author.no_result")
                    }
                }
            }
        }
        .applyListBackground()
        .searchable(text: $query, prompt: Text("create_book.author_field"))
        .autocorrectionDisabled()
        .navigationTitle(String(localized: "create_book.author_field"))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("e2e.createBook.author.picker")
        .task(id: query) {
            await search()
        }
        .onAppear {
            // The name already typed, if there is one, is the search everybody expects to see
            // run: coming back to change an author starts from that author.
            if query.isEmpty { query = draft.authorName }
        }
    }

    /// Runs the search a beat after the last keystroke. Cancellation is the debounce: a new
    /// query cancels this task, and the sleep is what gives it time to.
    private func search() async {
        guard trimmedQuery.count >= 2 else {
            results = []
            hasSearched = false
            return
        }

        try? await Task.sleep(for: AuthorPickerView.debounce)
        guard Task.isCancelled == false else { return }

        // A failed search is not a dead end here: the « create » row below is always there, and
        // an error message would say nothing the empty list does not.
        results = (try? await searchModel.searchEntity(query: trimmedQuery, entityTypes: [.humans])) ?? []
        hasSearched = true
    }

    /// An author inventaire.io already has: named by uri from here on, so the server reuses
    /// the entity instead of making a second one.
    private func choose(_ result: SearchResult) {
        draft.authorName = result.title
        draft.authorUri = result.uri
        draft.authorDescription = result.description
        dismiss()
    }

    /// An author nobody has entered yet: described by label, and created by the server along
    /// with the book.
    private func createAuthor() {
        draft.authorName = trimmedQuery
        draft.authorUri = nil
        draft.authorDescription = nil
        dismiss()
    }
}

/// One candidate: the name, and what tells two namesakes apart.
private struct AuthorPickerRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text(result.title)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)

            if let description = result.description, description.isEmpty == false {
                Text(description)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}
