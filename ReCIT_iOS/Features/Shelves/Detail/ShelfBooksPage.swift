//
//  ShelfBooksPage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  An étagère's « Livres » page: its books in an inset grouped list (`DesignSystem.FormList`),
//  newest first, each opening its book screen; on my own étagère a swipe takes a book off it, and
//  « Ajouter des livres » is pinned at the page's foot as a form's « Enregistrer » is
//  (`formActionBar`), so it leaves with the page and never stands under « Présentation ». One
//  page of `ShelfDetailView`'s pager.
//

import SwiftData
import SwiftUI

struct ShelfBooksPage: View {
    let shelf: Shelf
    let books: [InventoryItem]
    let isMine: Bool
    /// The height of the tabs laid over the page, which it leaves room for.
    let tabsHeight: CGFloat
    let onAddBooks: () -> Void

    @Binding var path: NavigationPath

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
                            ShelfBookRow(
                                item,
                                shelf: shelf,
                                isMine: isMine,
                                path: $path
                            )
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
}

private extension ShelfBooksPage {
    enum AccessibilityID {
        static let addBooks: String = "e2e.shelf.addBooks"
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
            onAddBooks: {},
            path: $path
        )
    }
}
