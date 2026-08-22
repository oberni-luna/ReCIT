//
//  SortShelvesGridView.swift
//  ReCIT_iOS
//
//  The scrolling half of the sorting surface: every étagère as a card, three to a row.
//
//  It scrolls and the panel below it does not, which is the decision the whole screen turns
//  on (PRD 0009): the source of a drag stays under the thumb while the destinations move
//  under the finger. The alternative — one long scroll with the books to file at the bottom
//  — puts the target off screen the moment the user goes looking for the right étagère.
//
//  Sections arrive already ordered by `SortProjection`: the étagères the server holds, then
//  the drafts in the order they were named. The pile of books to file is *not* drawn here —
//  it is the panel's, and the projection's last section is skipped for that reason.
//
//  The cards' width comes from `SortGridMetrics`, computed once by the screen and passed
//  down, so nothing here measures itself.
//

import SwiftUI

struct SortShelvesGridView: View {
    let sections: [SortSection]
    let plan: SortWritePlan
    let metrics: SortGridMetrics
    /// Whether the grid accepts gestures. False while an apply or a proposal owns the stack.
    let isActive: Bool
    /// Whether a run is writing right now — which the cards read to dim, breathe and tick.
    let isApplying: Bool
    /// Where one étagère stands in that run, or `nil` for one the plan leaves alone.
    let outcome: (SortSection.ID) -> SortApplyLedger.ShelfOutcome?
    /// Changes when a proposal lands, so every étagère it filled plays an arrival. Nil at rest.
    let arrivalToken: String?
    /// A section to bring into view, once. A new étagère is appended after the ones the server
    /// holds, so on a large collection it is born off screen and the form closes on a grid that
    /// looks unchanged.
    let scrollTarget: SortSection.ID?
    let onScrolled: () -> Void
    let onCreateShelf: () -> Void
    /// Opens the create form with a dropped book in hand. Returns whether the drop was taken.
    let onDropOnNewShelf: (String) -> Bool
    /// Files a carried book onto a section. Returns whether the drop was taken.
    let onDrop: (String, SortSection) -> Bool

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: .zero) {
                    ShelfSectionHeader(title: String(localized: "manual_sort.shelves_header"))

                    LazyVGrid(
                        columns: columns,
                        alignment: .leading,
                        spacing: SortGridMetrics.shelfSpacing
                    ) {
                        ForEach(sections.enumerated(), id: \.element.id) { index, section in
                            SortShelfCardCell(
                                section: section,
                                status: plan.status(of: section.id),
                                width: metrics.shelfColumnWidth,
                                isActive: isActive,
                                outcome: outcome(section.id),
                                isApplying: isApplying,
                                // Only the étagères a proposal actually filled: a card it left
                                // alone must not bounce, or the arrival would say the model
                                // touched the whole library.
                                arrivalToken: plan.status(of: section.id) == .untouched ? nil : arrivalToken,
                                arrivalDelay: Double(index) * SortPileView.landingStagger,
                                onDrop: { bookId in onDrop(bookId, section) }
                            )
                        }

                        SortNewShelfTileView(
                            width: metrics.shelfColumnWidth,
                            isActive: isActive,
                            onTap: onCreateShelf,
                            onDrop: onDropOnNewShelf
                        )
                        .id(Self.tileId)
                    }
                    .padding(.horizontal, .medium)
                }
                .padding(.bottom, .medium)
                .onChange(of: scrollTarget) { _, target in
                    guard target != nil else { return }
                    // The tile rather than the new card: a draft is drawn immediately before
                    // it, so bringing the tile into view shows both — and the tile is the one
                    // anchor whose identity does not depend on the library.
                    withAnimation { proxy.scrollTo(Self.tileId, anchor: .bottom) }
                    onScrolled()
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// The tile's scroll anchor. A constant because it is the one cell whose identity does not
    /// depend on the library.
    private static let tileId: String = "manual_sort.tile"

    /// Fixed rather than adaptive: the design fixes the number of columns at three and lets
    /// the cards narrow, so that the grid and the carousel below stay on the same rhythm.
    private var columns: [GridItem] {
        .init(
            repeating: .init(.fixed(metrics.shelfColumnWidth), spacing: SortGridMetrics.shelfSpacing),
            count: SortGridMetrics.columnCount
        )
    }
}
