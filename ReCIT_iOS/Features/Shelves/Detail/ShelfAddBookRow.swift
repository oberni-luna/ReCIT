//
//  ShelfAddBookRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  One of my books in « Ajouter des livres »: a checkbox before the inventory's own cell, the
//  whole row toggling it.
//

import SwiftData
import SwiftUI

struct ShelfAddBookRow: View {
    let item: InventoryItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: .sMedium) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isSelected ? .foregroundTinted : .foregroundSecondary)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)

                InventoryCell(item: item, filterParameter: .userInventory)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.row)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private extension ShelfAddBookRow {
    enum AccessibilityID {
        static let row: String = "e2e.shelf.addBooks.row"
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @Query var items: [InventoryItem]
    @Previewable @State var selected: Bool = true
    if let item = items.first {
        List {
            ShelfAddBookRow(
                item: item,
                isSelected: selected,
                onToggle: { selected.toggle() }
            )
        }
    }
}
