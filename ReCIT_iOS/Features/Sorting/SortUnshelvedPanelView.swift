//
//  SortUnshelvedPanelView.swift
//  ReCIT_iOS
//
//  The anchored foot of the sorting surface: the books that are on no étagère, then what
//  saving would do, then the three controls that do it.
//
//  **It does not scroll away**, and that is content rather than chrome — which is why the
//  argument PRD 0008 used against a pinned bar (a tab bar already underneath, 166 pt of
//  furniture) does not apply. Three things depend on it staying put: the drag always has a
//  source under the thumb, taking a book *off* an étagère always has a target on screen, and
//  « Appliquer » is never several screens below the work.
//
//  **One row of books, not two.** A second row costs another card's height of panel, taken
//  from the grid on every screen; the design settles for one row and lets the fourth card
//  peek, which is what says the row scrolls.
//
//  **« Livres à ranger » stays when it empties**, with its count at zero — it is the only
//  target that takes a book back out of an étagère, so removing it would kill half the
//  symmetry the gesture promises, and a count at zero is the only proof the work is done
//  (PRD 0008). What goes away is the carousel, and with it its height.
//
//  The carousel's height is reserved before the library has loaded, so nothing jumps when
//  the opening sync lands on a screen the user is already looking at.
//

import SwiftUI

struct SortUnshelvedPanelView: View {
    let books: [AutoSortBook]
    let metrics: SortGridMetrics
    /// Whether the opening sync is still running. The panel is drawn and inert, rather than
    /// absent: it holds the screen's shape while there is nothing to put in it.
    let isLoading: Bool
    /// Whether the panel accepts gestures. False while a run owns the stack.
    let isActive: Bool
    /// Whether a run is writing right now. The carousel dims with the grid: the whole screen
    /// is busy, and the books in here are the ones being filed away.
    let isApplying: Bool
    /// Takes a book off whatever étagère it is on. Returns whether the drop was taken.
    let onDrop: (String) -> Bool
    let footer: SortFooter
    let actions: SortActions

    /// Whether a dragged book is hovering the panel. The **whole** panel is the target: the
    /// order in here is arrival order, so aiming at a slot between two cards would mean
    /// nothing, and a 200 pt target is one a hand coming back from an étagère cannot miss.
    @State private var isTargeted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            ShelfSectionHeader(title: header)

            if isLoading {
                DesignSystem.Color.clear.color
                    .frame(height: metrics.carouselHeight)
            } else if books.isEmpty {
                Text("manual_sort.unshelved.empty")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, .medium)
            } else {
                carousel
                    .opacity(isApplying ? 0.8 : 1)
            }

            ManualSortActionBar(actions: actions)
                .padding(.horizontal, .medium)

            SortFooterView(footer: footer)
                .padding(.horizontal, .medium)
        }
        .padding(.top, .medium)
        .padding(.bottom, .small)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.backgroundDefault.color)
        .clipShape(
            .rect(
                topLeadingRadius: DesignSystem.CornerRadius.roundedLarge.rawValue,
                topTrailingRadius: DesignSystem.CornerRadius.roundedLarge.rawValue
            )
        )
        .overlay {
            if isTargeted {
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignSystem.CornerRadius.roundedLarge.rawValue,
                    topTrailingRadius: DesignSystem.CornerRadius.roundedLarge.rawValue
                )
                .strokeBorder(DesignSystem.Color.borderTinted.color, lineWidth: 2)
            }
        }
        .dropDestination(for: SortBookTransfer.self) { transfers, _ in
            guard isActive, let transfer = transfers.first else { return false }
            return onDrop(transfer.bookId)
        } isTargeted: { targeted in
            isTargeted = targeted && isActive
        }
        .onChange(of: isTargeted) { _, targeted in
            guard targeted else { return }
            Haptics.Impact.soft.play()
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: SortGridMetrics.bookSpacing) {
                ForEach(books) { book in
                    SortBookCardView(
                        book: book,
                        width: metrics.bookColumnWidth,
                        isDraggable: isActive
                    )
                }
            }
            .padding(.horizontal, .medium)
        }
        .frame(height: metrics.carouselHeight)
        .scrollIndicators(.hidden)
    }

    /// « Livres à ranger · N ». The count is the section's own, so it cannot disagree with
    /// the cards under it.
    private var header: String {
        .init(localized: "manual_sort.unshelved.header \(books.count)")
    }
}
