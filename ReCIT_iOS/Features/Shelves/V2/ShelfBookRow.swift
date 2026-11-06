//
//  ShelfBookRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  One book on an étagère's « Livres » page: the inventory's own cell, opening its book screen,
//  and on my own étagère a swipe taking it off, as on the first screen (`ShelfDetailView`).
//
//  Books are pushed through the path rather than a `NavigationLink`: the page lives in a hosting
//  controller of its own, as a reader's Inventaire tab does (`UserInventoryTab`).
//

import SwiftData
import SwiftUI

struct ShelfBookRow: View {
    let item: InventoryItem
    let shelf: Shelf
    let isMine: Bool

    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(ShelfModel.self) private var shelfModel: ShelfModel

    init(
        _ item: InventoryItem,
        shelf: Shelf,
        isMine: Bool,
        path: Binding<NavigationPath>
    ) {
        self.item = item
        self.shelf = shelf
        self.isMine = isMine
        self._path = path
    }

    var body: some View {
        Button {
            path.append(NavigationDestination.book(anchor: .item(item)))
        } label: {
            InventoryCell(item: item, filterParameter: .userInventory)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.book)
        // As on the first screen: nothing is deleted — the copy stays in the inventory and on
        // every other étagère — and the label names the étagère. Mine only.
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if isMine {
                Button(
                    "action.remove_from_shelf_named \(shelf.name)",
                    systemImage: "tray.and.arrow.up",
                    role: .destructive
                ) {
                    shelfModel.removeItem(item, from: shelf, modelContext: modelContext)
                }
                .tint(.foregroundError)
            }
        }
    }
}

private extension ShelfBookRow {
    enum AccessibilityID {
        static let book: String = "e2e.shelfV2.book"
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @State var path: NavigationPath = .init()
    @Previewable @Query var shelves: [Shelf]
    if let shelf = shelves.first, let item = shelf.items.first {
        List {
            ShelfBookRow(
                item,
                shelf: shelf,
                isMine: true,
                path: $path
            )
        }
    }
}
