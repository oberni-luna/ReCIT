//
//  ShelfBooksPage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  An étagère's « Livres » page in its v2 screen: its books in an inset grouped list
//  (`DesignSystem.FormList`), newest first, each opening its book screen; on my own étagère a
//  swipe takes a book off it, as on the first screen (`ShelfDetailView`), and « Ajouter des
//  livres » is pinned at the page's foot as a form's « Enregistrer » is (`formActionBar`), so it
//  leaves with the page and never stands under « Présentation ». One page of
//  `ShelfDetailV2View`'s pager.
//
//  Books are pushed through the path rather than a `NavigationLink`: the page lives in a hosting
//  controller of its own, as a reader's Inventaire tab does (`UserInventoryTab`).
//

import SwiftData
import SwiftUI

struct ShelfBooksPage: View {
    let shelf: Shelf
    let books: [InventoryItem]
    let isMine: Bool
    /// The height of the tabs laid over the page, which it leaves room for.
    let tabsHeight: CGFloat
    @Binding var path: NavigationPath
    let onAddBooks: () -> Void

    @Environment(ShelfModel.self) private var shelfModel: ShelfModel
    @Environment(\.modelContext) private var modelContext: ModelContext

    var body: some View {
        if shelf.isStillInTheStore {
            DesignSystem.FormList {
                Section {
                    if books.isEmpty {
                        Text("shelf.detail.empty")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundSecondary)
                    } else {
                        ForEach(books) { item in
                            bookButton(item)
                        }
                    }
                }
            }
            .listDetailTabsRoom(height: tabsHeight)
            .formActionBar(isPresented: isMine) {
                Button(action: onAddBooks) {
                    Text("shelf.add_books")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier(AccessibilityID.addBooks)
            }
        }
    }

    private func bookButton(_ item: InventoryItem) -> some View {
        Button {
            path.append(NavigationDestination.book(anchor: .item(item)))
        } label: {
            InventoryCell(item: item, filterParameter: .userInventory)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

private extension ShelfBooksPage {
    enum AccessibilityID {
        static let addBooks: String = "e2e.shelfV2.addBooks"
    }
}

#Preview("Mine", traits: .modifier(ShelfPreviewStore())) {
    @Previewable @State var path: NavigationPath = .init()
    @Previewable @Query var shelves: [Shelf]
    if let shelf = shelves.first {
        ShelfBooksPage(
            shelf: shelf,
            books: shelf.items,
            isMine: true,
            tabsHeight: 0,
            path: $path,
            onAddBooks: {}
        )
    }
}
