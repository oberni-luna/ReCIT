//
//  SearchAllMatchesView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// Where a local section's « Tout voir » leads: the same rows, uncapped. Books keep
/// `SearchAllLocalView`; lists, friends and groups go through `SearchAllMatchesList`.
struct SearchAllMatchesView: View {
    /// The query the section answered, carried from its header: the field is on the screen
    /// below.
    private let query: String
    private let kind: LocalSearchKind

    @Environment(UserModel.self) private var userModel: UserModel

    init(
        query: String,
        kind: LocalSearchKind
    ) {
        self.query = query
        self.kind = kind
    }

    var body: some View {
        switch kind {
        case .books:
            SearchAllLocalView(query: query)
        case .lists:
            everyMatch { sections in
                SearchAllMatchesList(.lists, items: sections.lists.items) { match in
                    SearchListRow(match)
                }
            }
        case .friends:
            everyMatch { sections in
                SearchAllMatchesList(.friends, items: sections.friends.items) { user in
                    SearchFriendRow(user)
                }
            }
        case .groups:
            everyMatch { sections in
                SearchAllMatchesList(.groups, items: sections.groups.items) { group in
                    SearchGroupRow(group)
                }
            }
        }
    }

    private func everyMatch<Content: View>(
        @ViewBuilder _ content: @escaping (LocalSearchSections) -> Content
    ) -> some View {
        LocalSearchSectionsReader(
            query,
            myUserId: userModel.myUser?._id,
            limit: InventorySearchRanking.noLimit,
            content: content
        )
    }
}

#Preview("Lists", traits: .modifier(SearchLocalPreviewStore())) {
    NavigationStack {
        SearchAllMatchesView(query: "bel", kind: .lists)
    }
}

#Preview("Friends", traits: .modifier(SearchLocalPreviewStore())) {
    NavigationStack {
        SearchAllMatchesView(query: "a", kind: .friends)
    }
}
