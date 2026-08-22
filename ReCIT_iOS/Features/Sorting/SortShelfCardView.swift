//
//  SortShelfCardView.swift
//  ReCIT_iOS
//
//  One étagère on the sorting grid: its books as a pile, its name, and how many books it
//  holds. It is three things at once — something to look at, something to drop a book on
//  (slice 0047), and the way into the étagère's own screen (slice 0049).
//
//  **The count lives in the title's own text**, per the design (`160:6797`): « Science
//  fiction et fantasy · 3 ». It is the one thing the grid loses next to the list it
//  replaces, and it is what decides where a book goes — "this one already has forty".
//
//  **The pill stays.** On a grid of identical white cards nothing else says that this
//  étagère does not exist on the server yet, or that this one's contents have changed. The
//  recap gives the totals; the pill says *which*. It comes out of `SortWritePlan`, the same
//  reduction the recap and the write come from, so the three cannot contradict each other.
//
//  Every measurement is a share of the width handed in (`SortGridMetrics`), so the card
//  returns a deterministic size and never measures itself — the rule ADR 0003 arrived at
//  after a self-measuring shelf caused a `UICollectionView` update loop.
//

import SwiftUI

struct SortShelfCardView: View {
    let section: SortSection
    let status: SortWritePlan.ShelfStatus
    let width: CGFloat
    /// Whether a dragged book is hovering this card. It grows a little and takes an accent
    /// border — enough to be unmistakable under a finger, little enough not to shove its
    /// neighbours around.
    var isTargeted: Bool = false
    /// Whether the front cover hands itself over to a drag.
    var isDraggable: Bool = true

    private var pile: SortPile { .init(section: section) }

    var body: some View {
        VStack(spacing: .xSmall) {
            SortPileView(pile: pile, width: width, isDraggable: isDraggable)

            Text(title)
                .textStyle(.footnote200Bold)
                .foregroundStyle(.foregroundDefault)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, .small)
        .padding(.horizontal, .xSmall)
        .frame(width: width, height: SortGridMetrics.cardHeight)
        .background(DesignSystem.Color.backgroundDefault.color)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.rounded.rawValue))
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: .rounded)
                    .strokeBorder(DesignSystem.Color.borderTinted.color, lineWidth: 2)
            }
        }
        .scaleEffect(isTargeted ? 1.03 : 1)
        .animation(.easeOut(duration: 0.15), value: isTargeted)
        // Top trailing, over the card's own corner: the pill is about the card, not about
        // any one book in it, and the pile is drawn towards the middle.
        .overlay(alignment: .topTrailing) {
            ManualSortStatusPill(status: status)
                .padding(.all, .xSmall)
        }
    }

    /// « Nom · N ». Built through the string catalogue so the separator and the plural are
    /// the translator's business, not Swift's — the divergence D38 the sorting surface has
    /// avoided since PRD 0008.
    private var title: LocalizedStringKey {
        "manual_sort.card.title \(section.name ?? "") \(section.bookCount)"
    }
}
