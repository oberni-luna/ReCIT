//
//  ShelvesContent.swift
//  ReCIT_iOS
//
//  The synced state of the bookshelf: a horizontal, snapping carousel of étagères
//  (A→Z) over a vertical list of all the user's books. Both are `@Query`-driven so
//  they stay reactive across syncs. Focusing the search hides the shelves and shows
//  the flat filtered list. See ADR 0003 / PRD 0001.
//

import SwiftUI
import SwiftData

struct ShelvesContent: View {
    let user: User
    let searchText: String
    @Binding var path: NavigationPath

    @Environment(\.isSearching) private var isSearching
    @Environment(ShelfFocusModel.self) private var focus

    /// Presents the create-shelf form, from the section header's "Ajouter" action — the only
    /// thing that opens it, now that the empty-state card runs an errand of its own. That
    /// header is the manual route, and it is the reason the card is free to lead elsewhere.
    @State private var isCreatingShelf: Bool = false

    /// Presents the batch scanner, from the empty-state card when the inventory is empty.
    /// A cover rather than a push, on `MainSearchView`'s pattern: the scanner owns its own
    /// navigation stack, and leaving it comes back here rather than unwinding this tab's path.
    @State private var isScanning: Bool = false

    @Query private var shelves: [Shelf]
    @Query private var myItems: [InventoryItem]

    private let horizontalPadding: CGFloat = 12
    private let gutter: CGFloat = 14

    init(user: User, searchText: String, path: Binding<NavigationPath>) {
        self.user = user
        self.searchText = searchText
        self._path = path

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
            List {
                InventoryListContent(
                    user: user,
                    searchText: searchText,
                    filterParameter: .userInventory,
                    sortParameter: .alphabetical
                )
            }
            .listStyle(.plain)
        } else {
            GeometryReader { geo in
                let cardWidth: CGFloat = geo.size.width * 0.86
                ScrollView {
                    ShelfSectionHeader(
                        title: "Étagères",
                        actionTitle: "Ajouter",
                        action: { isCreatingShelf = true }
                    )
                    .padding(.top, .medium)
                    // One or the other, never both: with no étagère there is nothing to
                    // page through, so the empty shelf stands in place of the carousel.
                    if shelves.isEmpty {
                        ShelfEmptyStateView(
                            width: cardWidth,
                            errand: emptyShelfErrand,
                            onTap: tapEmptyShelf
                        )
                            // Parked where the carousel's first card would be, so the
                            // first real étagère appears exactly here.
                            .padding(.horizontal, horizontalPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                .fullScreenCover(isPresented: $isScanning) {
                    BatchScanView()
                }
            }
        }
    }

    /// What the empty card's note asks for — and, through the switch in `tapEmptyShelf`, where
    /// its press goes. The label and the destination both read this one property, so they are a
    /// single decision rather than two that have to be kept in step.
    ///
    /// The card only appears when the user has no étagère, so the inventory is the whole
    /// question: no books, nothing to arrange yet. Reading an empty `@Query` as "empty" is only
    /// honest because `ShelvesView` reaches this content once the inventory has synced at least
    /// once — otherwise "empty" could as easily mean "not arrived yet", and the note would
    /// invite a user with three hundred books to go and scan them.
    private var emptyShelfErrand: ShelfEmptyStateErrand {
        .init(ownsBooks: !myItems.isEmpty)
    }

    /// The empty shelf's note states the next useful thing, and pressing it does that thing:
    /// with an empty inventory, scanning books in; with books already owned and no étagère to
    /// put them on, arranging them. Both are the same promise kept — the note is read, then
    /// acted on. See PRD 0007.
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
    /// What is different here is that the note changes with the state, so the affordance is
    /// stated before it is used. Nothing is substituted behind the label; the label *is* the
    /// state, and it and this switch come from the same `emptyShelfErrand`, so they cannot
    /// disagree. The rule that survives from 0006 is the one that mattered all along: a card
    /// must never open something other than what its label promises.
    ///
    /// The manual route is untouched either way — the section header's "Ajouter" creates an
    /// étagère by hand.
    private func tapEmptyShelf() {
        switch emptyShelfErrand {
        case .scan:
            isScanning = true
        case .sort:
            path.append(NavigationDestination.manualSort)
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
                Divider()
                    .padding(.leading, .medium)
            }
        }
    }
}
