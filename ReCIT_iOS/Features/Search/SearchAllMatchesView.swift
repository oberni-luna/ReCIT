//
//  SearchAllMatchesView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// Where a local section's « Tout voir » leads: the same rows, uncapped. Books keep
/// `SearchAllLocalView`; lists, friends and groups go through `SearchAllMatchesList`.
struct SearchAllMatchesView: View {
    /// The query the section answered, carried from its header: the field is on the screen
    /// below.
    private let query: String
    private let kind: LocalSearchKind

    @Environment(UserModel.self) private var userModel: UserModel
    @Environment(GroupModel.self) private var groupModel: GroupModel

    @Query private var lists: [EntityList]
    @Query private var users: [User]
    @Query private var storedGroups: [StoredGroup]

    init(
        query: String,
        kind: LocalSearchKind
    ) {
        self.query = query
        self.kind = kind
    }

    private var listMatches: LocalSearchMatches<ListSearchMatch> {
        .lists(
            lists,
            myUserId: userModel.myUser?._id,
            friends: users.filter { $0.relation == .friend },
            matching: query,
            limit: InventorySearchRanking.noLimit
        )
    }

    private var friendMatches: LocalSearchMatches<User> {
        .friends(
            in: users,
            matching: query,
            limit: InventorySearchRanking.noLimit
        )
    }

    private var groupMatches: LocalSearchMatches<ReaderGroup> {
        .groups(
            in: groupModel.myGroups(from: storedGroups),
            matching: query,
            limit: InventorySearchRanking.noLimit
        )
    }

    var body: some View {
        switch kind {
        case .books:
            SearchAllLocalView(query: query)
        case .lists:
            SearchAllMatchesList(.lists, items: listMatches.items) { match in
                SearchListRow(match)
            }
        case .friends:
            SearchAllMatchesList(.friends, items: friendMatches.items) { user in
                SearchFriendRow(user)
            }
        case .groups:
            SearchAllMatchesList(.groups, items: groupMatches.items) { group in
                SearchGroupRow(group)
            }
        }
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
