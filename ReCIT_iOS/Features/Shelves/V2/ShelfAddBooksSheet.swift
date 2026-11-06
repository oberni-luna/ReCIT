//
//  ShelfAddBooksSheet.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  « Ajouter des livres », opened from the foot of an étagère's « Livres » page: every book of
//  mine not on it yet, newest first, each with a checkbox, and pinned at the foot
//  « Ajouter N livres ». The button files the books in one optimistic `add-items`
//  (`ShelfModel.addItems`) and closes the sheet: the books are on the étagère behind it at once.
//
//  Books already on the étagère are left out rather than shown checked and greyed: the sheet is
//  a list of what can be added, and the page behind it already shows the rest.
//

import SwiftData
import SwiftUI

struct ShelfAddBooksSheet: View {
    let shelf: Shelf

    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(ShelfModel.self) private var shelfModel: ShelfModel

    @Query private var myItems: [InventoryItem]

    /// The books ticked, by server id: an id survives a sync replacing the copy under it.
    @State private var selectedIds: Set<String> = []

    init(shelf: Shelf) {
        self.shelf = shelf
        let ownerId: String = shelf.ownerId
        _myItems = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.created,
            order: .reverse
        )
    }

    /// My books not on the étagère yet.
    private var candidates: [InventoryItem] {
        let onShelf: Set<String> = .init(shelf.items.map(\._id))
        return myItems.filter { $0.isStillInTheStore && !onShelf.contains($0._id) }
    }

    private var selectedItems: [InventoryItem] {
        candidates.filter { selectedIds.contains($0._id) }
    }

    var body: some View {
        NavigationStack {
            DesignSystem.FormList {
                Section {
                    if candidates.isEmpty {
                        Text("shelf.add_books.empty")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundSecondary)
                    } else {
                        ForEach(candidates) { item in
                            ShelfAddBookRow(
                                item: item,
                                isSelected: selectedIds.contains(item._id),
                                onToggle: { toggle(item) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("shelf.add_books")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") { dismiss() }
                }
            }
            .formActionBar {
                Button(action: add) {
                    Text("shelf.add_books.submit \(selectedItems.count)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary())
                .disabled(selectedItems.isEmpty)
                .accessibilityIdentifier(AccessibilityID.submit)
            }
        }
    }

    private func toggle(_ item: InventoryItem) {
        if selectedIds.contains(item._id) {
            selectedIds.remove(item._id)
        } else {
            selectedIds.insert(item._id)
        }
    }

    private func add() {
        shelfModel.addItems(selectedItems, to: shelf, modelContext: modelContext)
        dismiss()
    }
}

private extension ShelfAddBooksSheet {
    enum AccessibilityID {
        static let submit: String = "e2e.shelfV2.addBooks.submit"
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @Query var shelves: [Shelf]
    if let shelf = shelves.first {
        ShelfAddBooksSheet(shelf: shelf)
    }
}
