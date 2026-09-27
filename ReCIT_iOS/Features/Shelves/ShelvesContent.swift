//
//  ShelvesContent.swift
//  ReCIT_iOS
//
//  The synced state of the bookshelf: a horizontal, snapping carousel of étagères
//  (A→Z) over a vertical list of all the user's books. Both are `@Query`-driven so
//  they stay reactive across syncs. Focusing the search hides the shelves and gives the
//  screen to the merged search surface. See ADR 0003 / PRD 0001 / PRD 0012.
//

import SwiftUI
import SwiftData

struct ShelvesContent: View {
    let user: User
    /// What is in the field, owned by `ShelvesView`. A binding because tapping a recent search
    /// puts its query back in the field (issue 0072).
    @Binding var searchText: String
    /// The search that has been sent, if one has — owned by `ShelvesView`, because the
    /// keyboard's « rechercher » key only reaches the field from above `.searchable`.
    @Binding var submission: SearchSuggestion?
    @Binding var path: NavigationPath
    /// Opens the inventory's search field — owned by `ShelvesView`, because only the view that
    /// carries `.searchable` can present it. The empty shelf's « Rechercher » tag is its caller.
    let onSearch: () -> Void

    @Environment(SortFlowPresentation.self) private var sortFlow
    @Environment(\.isSearching) private var isSearching
    @Environment(ShelfFocusModel.self) private var focus
    @Environment(InventoryModel.self) private var inventoryModel

    /// Presents the create-shelf form, from the section header's "Ajouter" action — the only
    /// thing that opens it, now that the empty-state card runs an errand of its own. That
    /// header is the manual route, and it is the reason the card is free to lead elsewhere.
    @State private var isCreatingShelf: Bool = false

    @Query private var shelves: [Shelf]
    @Query private var myItems: [InventoryItem]

    private let horizontalPadding: CGFloat = 12
    private let gutter: CGFloat = 14

    init(
        user: User,
        searchText: Binding<String>,
        submission: Binding<SearchSuggestion?>,
        path: Binding<NavigationPath>,
        onSearch: @escaping () -> Void
    ) {
        self.user = user
        self._searchText = searchText
        self._submission = submission
        self._path = path
        self.onSearch = onSearch

        let ownerId: String = user._id
        _shelves = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.name,
            order: .forward
        )
        _myItems = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.created,
            order: .reverse
        )
    }

    var body: some View {
        if isSearching {
            // The field used to filter this user's own books and stop there, which is how a
            // book two streets away came back as an empty list. It now opens the merged search
            // surface: my copies and my friends', past three characters, and the three ways on
            // to inventaire.io under them. See PRD 0012.
            InventorySearchContent(
                user: user,
                searchText: $searchText,
                submission: $submission
            )
        } else {
            GeometryReader { geo in
                let cardWidth: CGFloat = geo.size.width * 0.86
                ScrollView {
                    if syncState != .synced {
                        InventorySyncBanner(title: "sync.inventory.mine.title", state: syncState)
                            .padding(.all, .medium)
                            // The inventory's page is white, so the card is the secondary
                            // grey that lists sit on — the maquette's white on grey, inverted.
                            .background(.backgroundSecondary)
                            .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
                            .padding(.horizontal, .medium)
                            .padding(.top, .small)
                            .accessibilityIdentifier("e2e.shelves.syncBanner")
                    }

                    ShelfSectionHeader(
                        title: "Étagères",
                        actionTitle: "Ajouter",
                        action: { isCreatingShelf = true }
                    )
                    .padding(.top, .medium)
                    // One or the other, never both: with no étagère there is nothing to
                    // page through, so the empty shelf stands in place of the carousel.
                    if shelves.isEmpty {
                        // Held back until the first sync is over: its errand reads the store,
                        // and a store still filling would tell a reader with three hundred
                        // books to go and scan them.
                        if syncState == .synced {
                            ShelfEmptyStateView(
                                width: cardWidth,
                                errand: emptyShelfErrand,
                                onAction: perform
                            )
                                .accessibilityIdentifier("e2e.shelves.emptyCard")
                                // Centred: alone on the screen, a card parked where the
                                // carousel's first one would be read as off-centre. The
                                // first real étagère lands a little further left, at the
                                // same height — a sideways step, not a jump.
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        shelvesCarousel(cardWidth: cardWidth)
                    }

                    ShelfSectionHeader(title: "Tous les livres · \(myItems.count)")
                        .padding(.top, .large)
                    allBooksList
                }
                // Frozen while a shelf is being scrubbed, so the slide can't scroll the page.
                .scrollDisabled(focus.isArmed)
                .sheet(isPresented: $isCreatingShelf) {
                    ShelfFormView()
                }
            }
        }
    }

    /// What the empty card asks for — its sentence and its tags. Where each tag's press goes is
    /// the switch in `perform`, over the tag's own `ShelfEmptyStateAction`, so a tag's wording and
    /// its destination are a single decision rather than two that have to be kept in step.
    ///
    /// The card only appears when the user has no étagère, so the inventory is the whole
    /// question: no books, nothing to arrange yet. Reading an empty `@Query` as "empty" is only
    /// honest because the card waits for the inventory to have synced at least once
    /// (`syncState`) — otherwise "empty" could as easily mean "not arrived yet", and the note
    /// would invite a user with three hundred books to go and scan them.
    /// Where my inventory's first sync stands. Anything but `.synced` puts the banner up and
    /// keeps the empty card down.
    private var syncState: InventoryFirstSyncState {
        inventoryModel.firstSyncState(for: user)
    }

    private var emptyShelfErrand: ShelfEmptyStateErrand {
        .init(ownsBooks: !myItems.isEmpty)
    }

    /// The empty shelf states the next useful thing, and each of its tags does one way of doing
    /// it: with an empty inventory, scanning books in or looking them up; with books already
    /// owned and no étagère to put them on, arranging them. Each is the same promise kept — the
    /// tag is read, then acted on. See PRD 0007 and docs/features/0021.
    ///
    /// **This card had a second destination once and it was deliberately removed, so putting
    /// one back has to say how it differs.** What PRD 0006 took out was a *silent* substitution
    /// keyed on hardware: a note reading "Ranger mes livres" that opened a create-shelf form on
    /// a device where Apple Intelligence cannot run. The wording never changed, so the user had
    /// no way to see why they had landed on a form about naming a shelf — it read as the wrong
    /// screen rather than as an unsupported device, and the substitution hid the actual reason
    /// entirely. That fallback stays gone: on every device a note about tidying books leads into
    /// the sorting surface, and the surface itself states when the model cannot run.
    ///
    /// **The destination changed under that rule, not the rule** (PRD 0008). It used to be the
    /// auto-sort review screen, which was nothing but a proposal and so had to be a wall where
    /// no proposal could be made. The sorting surface sorts books by hand on any device, so the
    /// reason has shrunk from a wall to a sentence beside a missing button
    /// (`ManualSortProposalButton`) — still stated, one layer further in, and now next to a
    /// screen that works.
    ///
    /// What is different here is that the tags change with the state, so the affordance is
    /// stated before it is used. Nothing is substituted behind a label; each tag *is* the action
    /// it names, and it and this switch come from the same `ShelfEmptyStateAction`, so they
    /// cannot disagree. The rule that survives from 0006 is the one that mattered all along: a
    /// tag must never open something other than what it promises.
    ///
    /// The manual route is untouched either way — the section header's "Ajouter" creates an
    /// étagère by hand.
    private func perform(_ action: ShelfEmptyStateAction) {
        switch action {
        case .scan:
            sortFlow.presentScanning()
        case .search:
            onSearch()
        case .sort:
            sortFlow.presentSorting()
        }
    }

    /// Horizontal, snapping carousel of shelf cards (~86% width, next card peeking).
    /// Nested inside the page's vertical scroll; only this scrolls horizontally.
    private func shelvesCarousel(cardWidth: CGFloat) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: gutter) {
                ForEach(shelves) { shelf in
                    ShelfRowView(shelf: shelf, width: cardWidth, path: $path)
                        .frame(width: cardWidth)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, horizontalPadding)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        // Frozen while a scrub is on, so the slide moves the selection, not the cards.
        .scrollDisabled(focus.isArmed)
    }

    private var allBooksList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(myItems) { item in
                NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                    InventoryCell(item: item, filterParameter: .userInventory)
                        .padding(.horizontal, .medium)
                        .padding(.vertical, .small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("e2e.inventoryBook")
                Divider()
                    .padding(.leading, .medium)
            }
        }
    }
}
