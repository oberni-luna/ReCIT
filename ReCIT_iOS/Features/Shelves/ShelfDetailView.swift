//
//  ShelfDetailView.swift
//  ReCIT_iOS
//
//  A single étagère opened as a standard list of its books (same cell as the rest of
//  the inventory). Reached by tapping a shelf. See ADR 0003.
//
//  This is also where the étagère is edited: the shelf is a property of the screen that
//  shows it, so its form belongs to this screen's navigation bar rather than to the card
//  that led here. See PRD 0003.
//

import SwiftUI
import SwiftData

struct ShelfDetailView: View {
    let shelfId: String
    @Binding var path: NavigationPath

    @Query private var shelves: [Shelf]

    @State private var editing: Bool = false

    init(shelfId: String, path: Binding<NavigationPath>) {
        self.shelfId = shelfId
        self._path = path
        _shelves = Query(filter: #Predicate { $0._id == shelfId })
    }

    private var shelf: Shelf? { shelves.first }

    private var books: [InventoryItem] {
        (shelf?.items ?? []).sorted { $0.created > $1.created }
    }

    var body: some View {
        List {
            if books.isEmpty {
                Text("Cette étagère est vide")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            } else {
                ForEach(books) { item in
                    NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                        InventoryCell(item: item, filterParameter: .userInventory)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(shelf?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Gated on the lookup: the shelf comes back optional, and an ungated button would
            // open a form with no shelf to edit — which silently behaves as a *create* for an
            // étagère that was deleted or hasn't synced yet.
            //
            // Primary action rather than confirmation action: the confirmation slot means
            // "Done/Save" for a modal and renders prominent, which is the wrong weight for a
            // secondary action on a pushed screen. Title alongside the icon so a pencil on a
            // shelf of books isn't mistaken for annotating a book.
            if shelf != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Modifier", systemImage: "pencil") { editing = true }
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .sheet(isPresented: $editing) {
            if let shelf {
                ShelfFormView(shelf: shelf)
            }
        }
    }
}
