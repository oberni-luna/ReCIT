//
//  InventorySearchResultGroup.swift
//  ReCIT_iOS
//
//  One group of remote results — a header carrying its count, and the cells under it. It draws
//  nothing when it holds nothing, so a search that found only people does not leave an empty
//  « Livres · 0 » behind.
//
//  The cells are `SearchResultCell`, which already knows how to draw a work, a person and one of
//  my own copies, and the rows push onto the inventory tab's own `NavigationPath` through
//  `NavigationDestination` — no second stack, no case added to the enum. A result whose type has
//  no destination (nothing this screen asks for, today) still draws; it simply does not lead
//  anywhere, which is better than hiding an answer the server gave.
//
//  See PRD 0012.
//

import SwiftUI

struct InventorySearchResultGroup: View {
    let title: LocalizedStringKey
    let results: [SearchResult]

    var body: some View {
        if !results.isEmpty {
            Section(title) {
                ForEach(results) { result in
                    row(for: result)
                        // The name past compte-rendus count: it keeps meaning "a result that
                        // came back from inventaire.io", which is why the suggestions above
                        // carry an identifier of their own.
                        .accessibilityIdentifier("e2e.searchResult")
                        .padding(.vertical, .xSmall)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for result: SearchResult) -> some View {
        if let destination = NavigationDestination.destinationForSearchResult(result) {
            NavigationLink(value: destination) {
                SearchResultCell(result: result)
            }
        } else {
            SearchResultCell(result: result)
        }
    }
}
