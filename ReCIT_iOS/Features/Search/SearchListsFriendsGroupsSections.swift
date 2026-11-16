//
//  SearchListsFriendsGroupsSections.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// Recherche's Listes, Ami·es and Groupes, in that order, between my books and inventaire.io.
/// Read from the store, matched in memory: nothing asked of inventaire.io.
struct SearchListsFriendsGroupsSections: View {
    private let query: String
    private let myUserId: String

    @Environment(GroupModel.self) private var groupModel: GroupModel

    @Query private var lists: [EntityList]
    /// Every reader in the store. Friends are told apart in Swift: `relation` is computed, and a
    /// `#Predicate` cannot see it.
    @Query private var users: [User]
    @Query private var storedGroups: [StoredGroup]

    init(
        _ query: String,
        myUserId: String
    ) {
        self.query = query
        self.myUserId = myUserId
    }

    private var listMatches: LocalSearchMatches<ListSearchMatch> {
        .lists(
            lists,
            myUserId: myUserId,
            friends: users.filter { $0.relation == .friend },
            matching: query
        )
    }

    private var friendMatches: LocalSearchMatches<User> {
        .friends(in: users, matching: query)
    }

    private var groupMatches: LocalSearchMatches<ReaderGroup> {
        .groups(in: groupModel.myGroups(from: storedGroups), matching: query)
    }

    var body: some View {
        SearchMatchesSection(.lists, query: query, matches: listMatches) { match in
            SearchListRow(match)
        }

        SearchMatchesSection(.friends, query: query, matches: friendMatches) { user in
            SearchFriendRow(user)
        }

        SearchMatchesSection(.groups, query: query, matches: groupMatches) { group in
            SearchGroupRow(group)
        }
    }
}

#Preview(traits: .modifier(SearchLocalPreviewStore())) {
    NavigationStack {
        List {
            SearchListsFriendsGroupsSections("bel", myUserId: SearchLocalPreviewStore.myUserId)
        }
        .listStyle(.insetGrouped)
    }
}
