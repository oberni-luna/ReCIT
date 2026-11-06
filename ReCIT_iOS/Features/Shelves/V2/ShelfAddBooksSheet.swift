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
//  The search field under the bar narrows the list by title or author. It hides books, it does
//  not untick them: a book ticked then filtered out is still counted, and still added.
//

import SwiftData
import SwiftUI

struct ShelfAddBooksSheet: View {
    let shelf: Shelf

    @Query private var myItems: [InventoryItem]

    /// The books ticked, by server id: an id survives a sync replacing the copy under it.
    @State private var selectedIds: Set<String> = []
    @State private var query: String = ""

    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(ShelfModel.self) private var shelfModel: ShelfModel

    init(shelf: Shelf) {
        self.shelf = shelf
        let ownerId: String = shelf.ownerId
        _myItems = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.created,
            order: .reverse
        )
    }

    private var ownedItems: [InventoryItem] {
        myItems.filter(\.isStillInTheStore)
    }

    /// My books not on the étagère yet.
    private var candidates: [InventoryItem] {
        let onShelf: Set<String> = .init(shelf.items.map(\._id))
        return ownedItems.filter { !onShelf.contains($0._id) }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The candidates whose title or one of whose authors matches the search, all without one.
    /// Not `searchIndex`: it holds my own username, which every one of my books would match.
    private var visibleCandidates: [InventoryItem] {
        guard trimmedQuery.isEmpty == false else { return candidates }
        return candidates.filter { item in
            guard let edition = item.edition else { return false }
            return ([edition.title] + edition.displayedAuthorNames)
                .contains { $0.localizedStandardContains(trimmedQuery) }
        }
    }

    private var selectedItems: [InventoryItem] {
        candidates.filter { selectedIds.contains($0._id) }
    }

    var body: some View {
        NavigationStack {
            DesignSystem.FormList {
                Section {
                    if ownedItems.isEmpty {
                        EmptyStateView(
                            glyph: "books.vertical",
                            title: "shelf.add_books.no_books"
                        )
                        .listRowBackground(Color.clear)
                    } else if candidates.isEmpty {
                        Text("shelf.add_books.empty")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundSecondary)
                    } else if visibleCandidates.isEmpty {
                        EmptyStateView(
                            glyph: "magnifyingglass",
                            title: "shelf.add_books.search.empty \(trimmedQuery)"
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(visibleCandidates) { item in
                            ShelfAddBookRow(
                                item: item,
                                isSelected: selectedIds.contains(item._id),
                                onToggle: { toggle(item) }
                            )
                        }
                    }
                }
            }
            .navigationTitle(Text("shelf.add_books.title \(shelf.name)"))
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("shelf.add_books.search.prompt")
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") { dismiss() }
                        .accessibilityIdentifier(AccessibilityID.close)
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
        static let close: String = "e2e.shelfV2.addBooks.close"
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @Query var shelves: [Shelf]
    if let shelf = shelves.first {
        ShelfAddBooksSheet(shelf: shelf)
    }
}
