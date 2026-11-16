//
//  SearchListsFriendsGroupsSections.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// Recherche's Listes, Ami·es and Groupes, in that order, between my books and inventaire.io.
/// Read from the store, matched in memory: nothing asked of inventaire.io.
struct SearchListsFriendsGroupsSections: View {
    private let query: String
    private let myUserId: String

    init(
        _ query: String,
        myUserId: String
    ) {
        self.query = query
        self.myUserId = myUserId
    }

    var body: some View {
        LocalSearchSectionsReader(query, myUserId: myUserId) { sections in
            SearchMatchesSection(.lists, query: query, matches: sections.lists) { match in
                SearchListRow(match)
            }

            SearchMatchesSection(.friends, query: query, matches: sections.friends) { user in
                SearchFriendRow(user)
            }

            SearchMatchesSection(.groups, query: query, matches: sections.groups) { group in
                SearchGroupRow(group)
            }
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
