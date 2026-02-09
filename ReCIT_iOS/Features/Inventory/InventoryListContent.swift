//
//  InventoryList.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/02/2026.
//
import SwiftData
import SwiftUI

struct InventoryListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [InventoryItem]
    let filterParameter: InventoryItem.FilterParameter

    init(
        user: User,
        searchText: String = "",
        filterParameter: InventoryItem.FilterParameter = .userInventory,
        sortParameter: SortParameter = .recent
    ) {
        self.filterParameter = filterParameter
        let predicate = InventoryItem.predicate(user: user, filterParameter: filterParameter, searchText: searchText)

        switch sortParameter {
        case .recent: _items = Query(filter: predicate, sort: \.created, order: .reverse)
        case .alphabetical: _items = Query(filter: predicate, sort: \.edition?.title)
        }
    }

    var body: some View {
        ForEach(items) { item in
            NavigationLink(value: NavigationDestination.item(item: item)) {
                InventoryCell(item: item, filterParameter: filterParameter)
            }
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
