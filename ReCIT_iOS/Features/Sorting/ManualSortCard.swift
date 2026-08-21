//
//  ManualSortCard.swift
//  ReCIT_iOS
//
//  The white card an étagère's rows sit on, painted one row at a time.
//
//  `Section` used to draw this for free, but the sections had to be flattened into one
//  `ForEach` so a book could be dragged between them (see `ManualSortRows`). So the card
//  is reassembled here: each row rounds only the corners that are actually the card's,
//  and every row but the last carries the hairline under it — inset to the title, as the
//  design draws it, so the separator reads as dividing books rather than cutting the card
//  in half.
//
//  **It is a `listRowBackground`, not a background inside the row.** In edit mode the list
//  reserves a strip at the row's trailing edge for its reorder grip and shrinks the
//  content area to fit — so a card drawn inside the content stops short of the grip, and
//  the handle ends up floating in the margin instead of sitting in the card where the
//  design puts it. A row background is painted across the row's whole width, grip
//  included, so the card runs underneath it.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortCardBackground: View {

    let isTop: Bool
    let isBottom: Bool

    /// Whether this card needs the gap between groups above it. An étagère gets that gap
    /// from its header; a standalone card — the recap, the report — has no header, so
    /// without this it butts against the card above and the two read as one.
    let spacedAbove: Bool

    /// 16 (card inset) + 36 (cover) + 12 (gap) — where the title starts, which is where
    /// the design hangs the hairline.
    private let separatorInset: CGFloat = 64

    private let radius: CGFloat = DesignSystem.CornerRadius.medium.rawValue

    var body: some View {
        DesignSystem.Color.backgroundDefault.color
            .overlay(alignment: .bottom) {
                if isBottom == false {
                    DesignSystem.Color.borderDefault.color
                        .frame(height: 1)
                        .padding(.leading, separatorInset)
                }
            }
            .clipShape(
                .rect(
                    topLeadingRadius: isTop ? radius : .zero,
                    bottomLeadingRadius: isBottom ? radius : .zero,
                    bottomTrailingRadius: isBottom ? radius : .zero,
                    topTrailingRadius: isTop ? radius : .zero
                )
            )
            .padding(.horizontal, .medium)
            .padding(.top, spacedAbove ? DesignSystem.Spacing.sMedium.rawValue : .zero)
    }
}

extension View {

    /// Lays a row onto its étagère's card: the background behind it, and the insets that
    /// put its content where the design puts it — 16 pt inside a card that is itself 16 pt
    /// from the screen edge. Nothing at the trailing edge, which belongs to the grip.
    func manualSortCardRow(
        isTop: Bool,
        isBottom: Bool,
        spacedAbove: Bool = false
    ) -> some View {
        listRowInsets(
            .init(
                top: DesignSystem.Spacing.sMedium.rawValue
                    + (spacedAbove ? DesignSystem.Spacing.sMedium.rawValue : .zero),
                leading: DesignSystem.Spacing.medium.rawValue * 2,
                bottom: DesignSystem.Spacing.sMedium.rawValue,
                trailing: .zero
            )
        )
        .listRowBackground(
            ManualSortCardBackground(
                isTop: isTop,
                isBottom: isBottom,
                spacedAbove: spacedAbove
            )
        )
        .listRowSeparator(.hidden)
    }
}
