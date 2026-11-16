//
//  SearchListRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// A list found by Recherche, drawn as in the Lists tab — a friend's headed by their picture
/// and name. Opens the Liste, read-only when it is a friend's.
struct SearchListRow: View {
    private let match: ListSearchMatch

    init(_ match: ListSearchMatch) {
        self.match = match
    }

    var body: some View {
        if match.list.isStillInTheStore {
            NavigationLink(value: NavigationDestination.entityList(id: match.list._id)) {
                ListRowView(list: match.list, owner: match.owner)
            }
            .accessibilityIdentifier(AccessibilityID.row)
        }
    }
}

private extension SearchListRow {
    enum AccessibilityID {
        static let row: String = "e2e.searchList"
    }
}

#Preview(traits: .modifier(SearchLocalPreviewStore())) {
    NavigationStack {
        List {
            LocalSearchSectionsReader("bel", myUserId: SearchLocalPreviewStore.myUserId) { sections in
                ForEach(sections.lists.items) { match in
                    SearchListRow(match)
                }
            }
        }
    }
}
