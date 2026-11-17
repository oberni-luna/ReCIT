//
//  SearchMatchesSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// One of Recherche's capped local sections — Listes, Ami·es or Groupes. Not drawn without a
/// match; « Tout voir » in its header only when the cap hides one.
struct SearchMatchesSection<Element: Identifiable, Row: View>: View {
    private let kind: LocalSearchKind
    private let query: String
    private let matches: LocalSearchMatches<Element>
    private let row: (Element) -> Row

    init(
        _ kind: LocalSearchKind,
        query: String,
        matches: LocalSearchMatches<Element>,
        @ViewBuilder row: @escaping (Element) -> Row
    ) {
        self.kind = kind
        self.query = query
        self.matches = matches
        self.row = row
    }

    var body: some View {
        if !matches.items.isEmpty {
            Section {
                ForEach(matches.items) { element in
                    row(element)
                }
            } header: {
                SearchLocalHeader(
                    kind: kind,
                    query: query,
                    showsSeeAll: matches.isCapped
                )
            }
            .textCase(nil)
        }
    }
}

#Preview("Four friends, three shown", traits: .modifier(SearchLocalPreviewStore())) {
    @Previewable @Query var users: [User]
    NavigationStack {
        List {
            SearchMatchesSection(
                .friends,
                query: "a",
                matches: LocalSearchMatches<User>.friends(in: users, matching: "a")
            ) { user in
                SearchFriendRow(user)
            }
        }
        .listStyle(.insetGrouped)
    }
}
