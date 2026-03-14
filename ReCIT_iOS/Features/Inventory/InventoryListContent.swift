//
//  InventoryList.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/02/2026.
//
import SwiftData
import SwiftUI

struct InventoryListContent: View {
    /// Fetches all items for the given owner filter. The predicate never changes
    /// based on search text, keeping the @Query stable and reactive to store changes.
    @Query private var allItems: [InventoryItem]

    let filterParameter: InventoryItem.FilterParameter
    let searchText: String
    let sortParameter: SortParameter

    init(
        user: User,
        searchText: String = "",
        filterParameter: InventoryItem.FilterParameter = .userInventory,
        sortParameter: SortParameter = .recent
    ) {
        self.filterParameter = filterParameter
        self.searchText = searchText
        self.sortParameter = sortParameter

        let userId: String = user._id
        let predicate: Predicate<InventoryItem>
        switch filterParameter {
        case .othersInventory:
            predicate = #Predicate { item in item.ownerId != userId }
        case .userInventory:
            predicate = #Predicate { item in item.ownerId == userId }
        }

        switch sortParameter {
        case .recent:       _allItems = Query(filter: predicate, sort: \.created, order: .reverse)
        case .alphabetical: _allItems = Query(filter: predicate, sort: \.edition?.title)
        }
    }

    /// Items filtered in-memory by search text. SwiftUI re-evaluates this
    /// whenever `searchText` or `allItems` changes.
    private var displayItems: [InventoryItem] {
        let clean: String = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return allItems }
        return allItems.filter { $0.searchIndex.localizedStandardContains(clean) }
    }

    var body: some View {
        if displayItems.isEmpty {
            emptyView
        } else {
            ForEach(displayItems) { item in
                NavigationLink(value: NavigationDestination.item(item: item)) {
                    InventoryCell(item: item, filterParameter: filterParameter)
                }
            }
        }
    }

    @ViewBuilder
    var emptyView: some View {
        VStack {
            Text(.init(String(localized: .inventoryEmpty)))
                .textStyle(.action200)
                .foregroundStyle(.secondary)
        }
    }
}

extension InventoryListContent {
    enum SortParameter: String, CaseIterable, Identifiable {
        case recent, alphabetical
        var id: Self { self }
        var name: String { rawValue.capitalized }
    }
}
