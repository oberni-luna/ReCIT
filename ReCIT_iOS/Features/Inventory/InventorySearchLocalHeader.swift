//
//  InventorySearchLocalHeader.swift
//  ReCIT_iOS
//
//  The local section's header, and the way past its cap.
//
//  Same shape as the recents' header — a title, and one action pushed to the trailing edge —
//  because the two sections sit one under the other and a header that behaved differently in
//  each would read as two screens stacked.
//
//  The action is a `NavigationLink`, not a `Button`: « Tout voir » goes somewhere, and the link
//  appends onto the inventory tab's own `NavigationPath` the same way every row of the section
//  below it does. It is drawn only when the cap hides something — the caller passes the answer,
//  because only the ranking knows the uncapped total.
//
//  See PRD 0012 and issue 0075.
//

import SwiftUI

struct InventorySearchLocalHeader: View {
    /// The query the full listing will answer. Carried into the destination rather than read
    /// back from the field, so the screen shows the search this header was drawn for.
    let query: String
    /// Whether the cap is hiding anything — `true` past three matches, never at three or under.
    let showsSeeAll: Bool

    var body: some View {
        HStack {
            Text("inventory.search.local_section")

            Spacer()

            if showsSeeAll {
                NavigationLink(
                    "inventory.search.see_all",
                    value: NavigationDestination.localSearchResults(query: query)
                )
                .buttonStyle(.plain)
                .foregroundStyle(.foregroundTinted)
                .accessibilityIdentifier("e2e.searchLocal.seeAll")
            }
        }
    }
}
