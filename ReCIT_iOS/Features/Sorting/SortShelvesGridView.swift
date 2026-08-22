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
    let onOpen: (SortSection) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .zero) {
                ShelfSectionHeader(title: String(localized: "manual_sort.shelves_header"))

                LazyVGrid(
                    columns: columns,
                    alignment: .leading,
                    spacing: SortGridMetrics.shelfSpacing
                ) {
                    ForEach(sections) { section in
                        Button {
                            onOpen(section)
                        } label: {
                            SortShelfCardView(
                                section: section,
                                status: plan.status(of: section.id),
                                width: metrics.shelfColumnWidth
                            )
                        }
                        // Plain: the card is its own visual, and a style that scaled or
                        // tinted it on press would fight the drop highlight slice 0047 puts
                        // on the same card.
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, .medium)
            }
            .padding(.bottom, .medium)
        }
        .scrollIndicators(.hidden)
    }

    /// Fixed rather than adaptive: the design fixes the number of columns at three and lets
    /// the cards narrow, so that the grid and the carousel below stay on the same rhythm.
    private var columns: [GridItem] {
        .init(
            repeating: .init(.fixed(metrics.shelfColumnWidth), spacing: SortGridMetrics.shelfSpacing),
            count: SortGridMetrics.columnCount
        )
    }
}
