//
//  InventorySearchContent.swift
//  ReCIT_iOS
//
//  The inventory screen while its search field is open. It replaces what used to sit behind
//  `isSearching` — a flat list of the user's own books, and nothing else — with a surface
//  driven by `SearchPhase`, which is what lets the field stop meaning "filter my shelves" and
//  start meaning "find this book".
//
//  All four phases draw something now. Under three characters the screen still shows nothing
//  new rather than an empty section, which is the whole point of the threshold living in
//  `SearchPhase`: the silence is a decision, not an accident.
//
//  **The one phase that can have nothing to say draws an absence rather than a blank.** With
//  the field open and no search ever sent — first launch, or after « Effacer » — the surface
//  drops the `List` entirely and mounts `EmptyStateView`, the app's first reusable one
//  (issue 0073). Dropping the list is not a detail: it is what puts the block in the middle of
//  the band the keyboard leaves visible instead of the middle of the frame.
//
//  **Every submission passes through one place here**, which is what makes the recent searches
//  a list of things actually sent. The keyboard's « rechercher » key, a tap on a suggestion and
//  a tap on a recent all end up setting `submission`, and recording hangs off that change
//  rather than off each of the three gestures — three call sites would be three chances for one
//  of them to forget.
//
//  Both `@Query`s are the reactive ones ADR 0001 asks for — mine by owner id, my friends' by
//  its negation — and the matching happens in memory over what they already hold. No fetch, no
//  server call, nothing persisted: searching my own shelves is a read.
//
//  **The local section stays on screen once a search has been sent.** It is the half of the
//  answer this device already has, so a call that is still in flight — or one that failed —
//  never blanks the books the user could already see. That is also why a failure goes out
//  through `AppErrorReporter`, the app's one channel for background failures, instead of
//  becoming a row where results should be.
//
//  The remote call is the one piece of state this view owns, and it owns it because nothing
//  about it is persisted: `.task(id:)` keyed on the submission runs it, and **the same key
//  cancels it** — editing the query takes the screen out of `results`, which makes the active
//  submission `nil`, which cancels the call in flight and clears what it had brought back.
//
//  See PRD 0012.
//

import SwiftData
import SwiftUI

struct InventorySearchContent: View {
    let user: User
    /// What is in the field. A binding rather than a value, because tapping a recent search has
    /// to put its query back in the field — the phase is computed from what the field holds, so
    /// a recent that only set `submission` would leave the screen on its own recents.
    @Binding var searchText: String
    /// What has been sent, and what it asked for. A suggestion rather than a string, because
    /// the keyboard's « rechercher » key and a tap on a row are the same gesture with different
    /// entity types — see `SearchSuggestion`.
    @Binding var submission: SearchSuggestion?

    @Environment(\.isSearching) private var isSearching
    @Environment(SearchModel.self) private var searchModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(RecentSearchStore.self) private var recentSearchStore

    @Query private var myItems: [InventoryItem]
    @Query private var friendsItems: [InventoryItem]

    /// What inventaire.io answered, for as long as the screen is showing that answer. Not
    /// persisted, and not `SearchModel`'s business: it is one screen's view of one query, and
    /// an app-scoped model holding it would outlive the question.
    @State private var remoteResults: [SearchResult] = []

    /// How long a submission waits before it leaves. Two submissions in a row — the keyboard
    /// key, then a suggestion — cost one call rather than two.
    private let debounce: Duration = .milliseconds(250)

    init(
        user: User,
        searchText: Binding<String>,
        submission: Binding<SearchSuggestion?>
    ) {
        self.user = user
        self._searchText = searchText
        self._submission = submission

        let ownerId: String = user._id
        _myItems = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.created,
            order: .reverse
        )
        _friendsItems = Query(
            filter: #Predicate { $0.ownerId != ownerId },
            sort: \.created,
            order: .reverse
        )
    }

    private var phase: SearchPhase? {
        SearchPhase.current(
            isFocused: isSearching,
            query: searchText,
            submittedQuery: submission?.query
        )
    }

    /// The query the local section searches for — set past the threshold, and kept while the
    /// remote results are showing: what I own is part of the answer either way.
    private var localQuery: String? {
        switch phase {
        case .suggesting(let query), .results(let query):
            query
        default:
            nil
        }
    }

    /// The submission the screen is currently showing results for, or `nil` — the query has
    /// been edited since, or nothing was ever sent. It is the `.task` key, so it is also what
    /// cancels a call whose query the user has already replaced.
    private var activeSubmission: SearchSuggestion? {
        guard case .results(let query) = phase, let submission, submission.query == query else {
            return nil
        }

        return submission
    }

    /// The recents the screen would draw right now — the displayed three, or nothing at all
    /// when the field is past the threshold and the recents have given the screen away.
    private var recentSearches: [String] {
        guard case .recents = phase else { return [] }

        return recentSearchStore.recentSearches(userId: user._id)
    }

    /// Whether the screen has nothing but an absence to show: the field is open, empty, and no
    /// search has ever been sent from this account on this device. First launch, and the state
    /// « Effacer » comes back to.
    private var showsEmptyRecents: Bool {
        if case .recents = phase {
            recentSearches.isEmpty
        } else {
            false
        }
    }

    var body: some View {
        Group {
            if showsEmptyRecents {
                // Not in a `List`. A scroll view keeps its full height under the keyboard and
                // insets its content instead, so a row centred in it would land behind the
                // keys; a plain container is laid out inside the safe area, and the keyboard
                // *is* a safe-area inset. Filling that container and centring in it therefore
                // centres the block in the band the keyboard leaves visible — the maquette's
                // 177 pt block at y=225 is exactly the middle of the 111 → 516 band, so the
                // arithmetic is the geometry, not an offset to hand-tune.
                EmptyStateView(
                    glyph: "magnifyingglass",
                    title: "inventory.search.recents.empty.title",
                    message: "inventory.search.recents.empty.message"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundSecondary)
                .accessibilityIdentifier("e2e.searchRecents.empty")
            } else {
                List {
                    InventorySearchRecentsSection(
                        searches: recentSearches,
                        onSelect: select(recent:),
                        onClear: { recentSearchStore.clear(userId: user._id) }
                    )

                    if let localQuery {
                        InventorySearchLocalSection(
                            query: localQuery,
                            ownerId: user._id,
                            myItems: myItems,
                            friendsItems: friendsItems
                        )
                    }

                    if case .suggesting(let query) = phase {
                        InventorySearchSuggestionsSection(query: query) { suggestion in
                            submission = suggestion
                        }
                    }

                    if case .results = phase {
                        InventorySearchResultsSection(results: remoteResults)
                    }
                }
                .listStyle(.plain)
                .applyListBackground()
            }
        }
        .task(id: activeSubmission) {
            await search()
        }
        // The one place a sent search becomes a remembered one. Hung off the submission rather
        // than off the three gestures that set it, so a fourth way to submit cannot arrive
        // without its query joining the recents.
        .onChange(of: submission) { _, newValue in
            guard let newValue else { return }
            recentSearchStore.record(query: newValue.query, userId: user._id)
        }
    }

    /// Runs a recent search again. It fills the field as well as submitting, because the phase
    /// is computed from what the field holds: a submission alone would send the call and leave
    /// the screen showing the recents it was tapped from.
    ///
    /// Everything in the history was sent from above the threshold, so `everything(for:)` never
    /// comes back empty here — and if it ever did, the field would simply keep what was tapped.
    private func select(recent query: String) {
        searchText = query
        if let everything = SearchSuggestion.everything(for: query) {
            submission = everything
        }
    }

    /// Runs the submitted search, or clears what the last one brought back when there is no
    /// longer one to run. Never throws: a failure here is a background failure like any other,
    /// and the user reads it in the SnackBar `MainTabView` observes.
    private func search() async {
        remoteResults = []
        guard let activeSubmission else { return }

        // A cancelled sleep is a query that moved on, not an error.
        try? await Task.sleep(for: debounce)
        guard !Task.isCancelled else { return }

        do {
            remoteResults = try await searchModel.searchEntity(
                query: activeSubmission.query,
                entityTypes: activeSubmission.entityTypes
            )
        } catch {
            // `URLSession` reports a cancelled request as an error of its own rather than as a
            // `CancellationError`, and a query the user has already replaced is nothing to
            // report.
            guard !Task.isCancelled else { return }
            errorReporter.report(error)
        }
    }
}
