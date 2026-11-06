//
//  SearchTabView.swift
//  ReCIT_iOS
//
//  The Recherche tab's root: its own navigation stack, the field, and the search that has been
//  sent. Everything here used to be held by `ShelvesView`, the inventory's root, when the field
//  lived in the inventory's navigation bar (PRD 0012); it moved as is when the search got a tab
//  with the system's search role (PRD 0020), which iOS lays out apart at the end of the bar.
//
//  Nothing resets on leaving: the query, the results and whatever was pushed from them are
//  where the reader left them when they come back, and `SearchContent` does not ask
//  inventaire.io again for an answer it already has.
//
//  Selecting the tab leaves the keyboard down — its rest state has things to show that the
//  keyboard would cover. Two things raise the field: the empty shelf's « Rechercher » tag, and a
//  tap on this tab while it is already showing, which also goes back to the root. Both arrive
//  through `TabRouter`.
//
//  « Nouveau livre », opened from the absence of « Sur inventaire.io », is held here too: the
//  sheet, what was typed in it by query while the tab lives, and the push of the new edition's
//  Fiche livre on this stack once it is published.
//
//  See PRD 0020 and issue 0116.
//

import SwiftUI

struct SearchTabView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(TabRouter.self) private var router

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    /// The search that has been sent — the query and the entity types it asked inventaire.io
    /// for. It lives here rather than in the search surface because `.onSubmit(of: .search)`
    /// only reaches the field from the view that carries `.searchable`, or from above it.
    /// Nothing clears it: a query edited afterwards stops matching what was sent, and that is
    /// what takes the screen back out of its results (`SearchPhase`).
    @State private var submission: SearchSuggestion?
    /// Whether the field is up. Held so `TabRouter` can raise it: `.searchable` only takes that
    /// from a binding.
    @State private var isSearchPresented: Bool = false

    /// The query « Nouveau livre » is up for, and nothing else: the sheet presents on it.
    @State private var newBookOrigin: NewBookOrigin?
    /// What was typed in « Nouveau livre » and not published, by query.
    @State private var newBookDrafts: NewBookDrafts = .init()
    /// The edition just published, opened once its sheet has gone.
    @State private var createdBookURI: String?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let user = userModel.myUser {
                    SearchContent(
                        user: user,
                        searchText: $searchText,
                        submission: $submission
                    )
                } else {
                    SyncingPlaceholderView()
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("nav.search")
            // Pinned under the title rather than left to the system. iOS 27 lays the search
            // tab out in the bar with the others, and a field placed automatically there only
            // shows once something activates it — selecting the tab left nothing to type in.
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always)
            )
            // The keyboard's « rechercher » key sends the query against both books and people
            // — the same thing the third suggestion does, and the same value, so the two
            // gestures cannot end up asking inventaire.io for different things. Below three
            // characters it sends nothing: `SearchSuggestion` reads the threshold rather than
            // keeping a second copy of it.
            .onSubmit(of: .search) {
                if let everything = SearchSuggestion.everything(for: searchText) {
                    submission = everything
                }
            }
        }
        .environment(\.openNewBook, .init { newBookOrigin = $0 })
        .sheet(item: $newBookOrigin, onDismiss: openCreatedBook) { origin in
            NewBookFlowView(
                origin: origin,
                draft: newBookDrafts.draft(for: origin),
                onCreated: { book in
                    newBookDrafts.forget(origin)
                    createdBookURI = book.uri
                },
                onKeepDraft: { newBookDrafts.remember($0, for: origin) }
            )
        }
        // On appearing as well as on change: the first request made is usually the one that
        // builds this tab, and it is already standing by the time the tab exists to see it.
        .onAppear(perform: raiseFieldIfAsked)
        .onChange(of: router.wantsSearchField) { _, wants in
            if wants {
                raiseFieldIfAsked()
            }
        }
        .onChange(of: router.searchRootRequest) { _, _ in
            path = .init()
        }
    }

    /// Opens the Fiche livre of the book « Nouveau livre » has just published, if it has.
    private func openCreatedBook() {
        guard let createdBookURI else { return }
        self.createdBookURI = nil
        path.append(NavigationDestination.book(anchor: .edition(uri: createdBookURI)))
    }

    private func raiseFieldIfAsked() {
        if router.consumeSearchFieldRequest() {
            isSearchPresented = true
        }
    }
}
