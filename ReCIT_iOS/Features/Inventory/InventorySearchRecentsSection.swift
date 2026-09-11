//
//  InventorySearchRecentsSection.swift
//  ReCIT_iOS
//
//  « Recherches récentes » — the first thing the field shows, before a single character is
//  typed. Repeating a search costs one tap instead of retyping a title nobody spells the same
//  way twice.
//
//  The rows are `SearchQueryRow`, the same view the three ways on to inventaire.io use: a clock
//  instead of a book, and a bare query instead of a sentence with the query emphasised inside
//  it. That is the whole difference, and it is why there is one row view in this feature rather
//  than two that would drift apart under Dynamic Type.
//
//  « Effacer » lives in the header rather than beside each row: this slice wipes the history
//  whole, and per-entry deletion is out of scope for PRD 0012. A header action also keeps the
//  three rows to one tap target each — the band between the field and the keyboard is about
//  516 pt tall, and it has the suggestions to fit as well.
//
//  Nothing is drawn when the history is empty. What to say instead is issue 0073's question,
//  which is also where the app gets its first reusable empty state.
//
//  See PRD 0012 and issue 0072.
//

import SwiftUI

struct InventorySearchRecentsSection: View {
    /// The searches to draw, most recent first — already capped by the store.
    let searches: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        if !searches.isEmpty {
            Section {
                ForEach(searches, id: \.self) { query in
                    SearchQueryRow(
                        glyph: "clock",
                        label: AttributedString(query)
                    ) {
                        onSelect(query)
                    }
                    // Its own identifier, never `e2e.searchResult`: a recent search is a way
                    // back to a result, not one, and past compte-rendus count what that name
                    // matched.
                    .accessibilityIdentifier("e2e.searchRecent")
                }
            } header: {
                HStack {
                    Text("inventory.search.recents_section")

                    Spacer()

                    Button("inventory.search.recents.clear", action: onClear)
                        .buttonStyle(.plain)
                        .foregroundStyle(.foregroundTinted)
                        .accessibilityIdentifier("e2e.searchRecents.clear")
                }
            }
        }
    }
}
