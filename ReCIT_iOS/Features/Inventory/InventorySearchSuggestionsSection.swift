//
//  InventorySearchSuggestionsSection.swift
//  ReCIT_iOS
//
//  « Chercher sur inventaire.io » — the three rows that take a query past what this device
//  already holds. They sit under the local section rather than above it, because the first
//  question the screen answers is "do I already own this?", and the road out only matters once
//  that answer is no.
//
//  The section draws what `SearchSuggestion` decides: the order of the three, the glyph of each
//  and the entity types each will ask for. This file chooses nothing — it hands the chosen
//  suggestion straight back to the screen, which submits it. That is why a tap and the
//  keyboard's « rechercher » key end up in the same place with the same shape of value.
//
//  See PRD 0012.
//

import SwiftUI

struct InventorySearchSuggestionsSection: View {
    let query: String
    let onSelect: (SearchSuggestion) -> Void

    var body: some View {
        let suggestions: [SearchSuggestion] = SearchSuggestion.suggestions(for: query)

        if !suggestions.isEmpty {
            Section("inventory.search.remote_section") {
                ForEach(suggestions) { suggestion in
                    SearchQueryRow(
                        glyph: suggestion.glyph,
                        label: suggestion.label,
                        spokenLabel: suggestion.spokenLabel
                    ) {
                        onSelect(suggestion)
                    }
                    // Its own identifier, never `e2e.searchResult`: a suggestion is a way to a
                    // result, not one, and past compte-rendus count what that name matched.
                    .accessibilityIdentifier("e2e.searchSuggestion.\(suggestion.kind.rawValue)")
                }
            }
        }
    }
}
