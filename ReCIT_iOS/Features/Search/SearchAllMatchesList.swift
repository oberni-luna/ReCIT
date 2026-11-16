//
//  SearchAllMatchesList.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// Every match of one local section, uncapped — where its « Tout voir » leads. Laid out like
/// `SearchAllLocalView`, titled like the section.
struct SearchAllMatchesList<Element: Identifiable, Row: View>: View {
    private let kind: LocalSearchKind
    private let items: [Element]
    private let row: (Element) -> Row

    init(
        _ kind: LocalSearchKind,
        items: [Element],
        @ViewBuilder row: @escaping (Element) -> Row
    ) {
        self.kind = kind
        self.items = items
        self.row = row
    }

    var body: some View {
        List {
            ForEach(items) { element in
                row(element)
            }
        }
        .listStyle(.plain)
        .applyListBackground()
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview(traits: .modifier(SearchLocalPreviewStore())) {
    @Previewable @Query var users: [User]
    NavigationStack {
        SearchAllMatchesList(
            .friends,
            items: LocalSearchMatches<User>.friends(
                in: users,
                matching: "a",
                limit: InventorySearchRanking.noLimit
            )
            .items
        ) { user in
            SearchFriendRow(user)
        }
    }
}
