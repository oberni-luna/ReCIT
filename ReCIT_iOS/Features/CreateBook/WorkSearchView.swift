//
//  WorkSearchView.swift
//  ReCIT_iOS
//
//  « De quel livre s'agit-il ? » — the question the sheet opens on when a scan found no edition.
//
//  Most of the time it is *this edition* that inventaire.io lacks, not the book: the work — the
//  text, its authors — is already there, and the reader only has to point at it. So the sheet
//  searches for the work first, with the field open, and creating one comes last, under the
//  results. Frames `V1`, `V2` and `V4` of « Nouveau livre v2 » in the Figma file.
//
//  The search is `SearchModel`'s, restricted to works. It finds a work by its author's name as
//  well as by its title — checked against production on 2026-10-25 — so there is no need to
//  search people and walk from an author to their works. Each result is completed by
//  `EntityCreationModel.describeWorks`, for the authors and the year a cover is recognised by.
//
//  « Modifier l'édition » pushes the same screen to change the work an edition belongs to, with
//  its own words before anything is typed: there, the ISBN is known, and saying it is not would
//  be false.
//
//  See PRD 0026.
//

import SwiftUI

struct WorkSearchView: View {
    @Environment(SearchModel.self) private var searchModel
    @Environment(EntityCreationModel.self) private var creationModel

    /// The barcode, said back in the opening sentence: it is the one thing the reader knows the
    /// app has understood.
    let isbn: String

    /// A work inventaire.io already has: the edition is attached to it.
    let onChoose: (WorkCandidate) -> Void

    /// None of the works fits: one is created, named after what was searched.
    let onCreate: (String) -> Void

    /// What the screen says before anything is typed. By default a new book's: inventaire.io
    /// does not know this ISBN.
    var emptyTitle: LocalizedStringKey = "create_book.search.empty.title"
    var emptyMessage: LocalizedStringKey?

    @State private var query: String = ""
    @State private var results: [WorkCandidate] = []
    @State private var hasSearched: Bool = false
    @State private var isSearchPresented: Bool = false

    /// Long enough that typing a title does not fire a request per letter, short enough that the
    /// list feels like it is following the hand. The author picker's, for the same reasons.
    private static let debounce: Duration = .milliseconds(300)

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        DesignSystem.FormList {
            BibliographicDataNotice()

            if trimmedQuery.isEmpty {
                Section {
                    EmptyStateView(
                        glyph: "magnifyingglass",
                        title: emptyTitle,
                        message: emptyMessage ?? "create_book.search.empty.message \(isbn)"
                    )
                    .padding(.vertical, .xLarge)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
            } else if results.isEmpty == false {
                Section {
                    ForEach(results) { work in
                        Button {
                            onChoose(work)
                        } label: {
                            WorkRow(work: work, showsDisclosure: true)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    CreateBookSectionHeader("create_book.search.results")
                } footer: {
                    CreateBookSectionFooter("create_book.search.why_existing")
                }

                Section {
                    WorkSearchCreateRow(title: "create_book.search.none_match") {
                        onCreate(trimmedQuery)
                    }
                }
            } else {
                Section {
                    WorkSearchCreateRow(title: "create_book.search.create \(trimmedQuery)") {
                        onCreate(trimmedQuery)
                    }
                } footer: {
                    if hasSearched {
                        CreateBookSectionFooter("create_book.search.no_result")
                    }
                }
            }
        }
        .searchable(
            text: $query,
            isPresented: $isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("create_book.search.prompt")
        )
        .autocorrectionDisabled()
        .bibliographicDataHelpButton()
        .accessibilityIdentifier("e2e.createBook.search")
        .task(id: query) {
            await search()
        }
        .onAppear {
            // Open, as the sheet appears: the reader came here with a book in hand and its title
            // on the cover, and the first thing to do is type it.
            if query.isEmpty { isSearchPresented = true }
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

        try? await Task.sleep(for: WorkSearchView.debounce)
        guard Task.isCancelled == false else { return }

        // A failed search is not a dead end: the « create » row is always there, and an error
        // message would say nothing the empty list does not.
        let found: [SearchResult] = (try? await searchModel.searchEntity(query: trimmedQuery, entityTypes: [.works])) ?? []
        let described: [WorkCandidate] = await creationModel.describeWorks(found)
        guard Task.isCancelled == false else { return }

        results = described
        hasSearched = true
    }
}

/// « Créer l'œuvre », always under the results: the way out when none of them is the book.
private struct WorkSearchCreateRow: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus")
                .textStyle(.content300)
                .foregroundStyle(.foregroundTinted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.createBook.work.create")
    }
}
