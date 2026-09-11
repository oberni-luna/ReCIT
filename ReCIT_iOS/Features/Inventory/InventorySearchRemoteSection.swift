//
//  InventorySearchRemoteSection.swift
//  ReCIT_iOS
//
//  The inventaire.io half of the search surface, once a query has been sent: the grouped
//  results, or the one thing to say instead of them.
//
//  It draws whatever `RemoteSearchState.sign` answers and nothing else, which is what keeps
//  « ça charge », « il n'y a rien » and « ça n'a pas marché » from ever appearing together or
//  being mistaken for one another — the arithmetic is in the state, the view only has three
//  branches to render (issue 0076).
//
//  **The local section is not in here, and that is the point.** It sits above, drawn by
//  `InventorySearchContent` for as long as the query stands, so a call still in flight — or one
//  that failed — never blanks the books this device could already show. A dead connection must
//  not look like an empty library.
//
//  The loading sign is `SyncingInlineRow`, the app's existing "this is still coming" row, with
//  a sentence of its own: a second hand-written inline spinner would have been a second answer
//  to a solved question. The two absences are `EmptyStateView` (issue 0073), which is the
//  « C · Recherche sans résultat » proposal of the 2026-08-28 « États vides » pass —
//  `Empty State` (`204:263`), `Layout=Centered` — adopted here, where the state it was drawn
//  for actually happens.
//
//  The failure carries the way out: the SnackBar says what went wrong and then goes away, so
//  the screen keeps the only thing still actionable — a button that sends the same query again.
//
//  Its copy is its own, never the recents' one: a query that found nothing and a history that
//  holds nothing are two different silences, and one text for both would say neither.
//
//  See PRD 0012.
//

import SwiftUI

struct InventorySearchRemoteSection: View {
    /// What the remote call is doing, and what it brought back.
    let state: RemoteSearchState
    /// The query that was sent — named in the "no result" sentence, so the screen says what it
    /// did not find rather than that something, somewhere, is empty.
    let query: String
    /// Sends the same query again. The only thing left to do after a failure.
    let onRetry: () -> Void

    var body: some View {
        switch state.sign {
        case .loading:
            SyncingInlineRow(message: "inventory.search.loading")
                .accessibilityIdentifier("e2e.searchLoading")

        case .noResult:
            EmptyStateView(
                glyph: "magnifyingglass",
                title: "inventory.search.results.empty.title",
                message: "inventory.search.results.empty.message \(query)"
            )
            // An absence is a statement about the whole answer, not one of its lines: no
            // separator under it, and room around it so it does not read as a result.
            .padding(.vertical, .large)
            .listRowSeparator(.hidden)
            .accessibilityIdentifier("e2e.searchNoResult")

        case .failure:
            EmptyStateView(
                glyph: "wifi.slash",
                title: "inventory.search.error.title",
                message: "inventory.search.error.message",
                action: .init(title: "inventory.search.error.retry", handler: onRetry)
            )
            .padding(.vertical, .large)
            .listRowSeparator(.hidden)
            .accessibilityIdentifier("e2e.searchError")

        case nil:
            InventorySearchResultsSection(results: state.results)
        }
    }
}

#Preview("Chargement") {
    List {
        InventorySearchRemoteSection(state: .loading, query: "monte cristo") {}
    }
}

#Preview("Aucun résultat") {
    List {
        InventorySearchRemoteSection(state: .loaded([]), query: "monte cristo") {}
    }
}

#Preview("Échec") {
    List {
        InventorySearchRemoteSection(state: .failed, query: "monte cristo") {}
    }
}
