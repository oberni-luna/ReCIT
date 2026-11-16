//
//  LocalSearchSectionsReader.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 17/11/2026.
//

import SwiftData
import SwiftUI

/// Reads the lists, readers and groups the store holds, and hands `content` what Listes, Ami·es
/// and Groupes find in them for the query. The one place those sections query the store, for
/// Recherche and for « Tout voir » alike.
struct LocalSearchSectionsReader<Content: View>: View {
    private let query: String
    private let myUserId: String?
    private let limit: Int
    private let content: (LocalSearchSections) -> Content

    @Environment(GroupModel.self) private var groupModel: GroupModel

    @Query private var lists: [EntityList]
    /// Every reader in the store. Friends are told apart in Swift: `relation` is computed, and a
    /// `#Predicate` cannot see it.
    @Query private var users: [User]
    @Query private var storedGroups: [StoredGroup]

    init(
        _ query: String,
        myUserId: String?,
        limit: Int = InventorySearchRanking.displayLimit,
        @ViewBuilder content: @escaping (LocalSearchSections) -> Content
    ) {
        self.query = query
        self.myUserId = myUserId
        self.limit = limit
        self.content = content
    }

    var body: some View {
        content(
            .init(
                lists: lists,
                users: users,
                myGroups: groupModel.myGroups(from: storedGroups),
                myUserId: myUserId,
                query: query,
                limit: limit
            )
        )
    }
}

#Preview(traits: .modifier(SearchLocalPreviewStore())) {
    NavigationStack {
        List {
            LocalSearchSectionsReader("a", myUserId: SearchLocalPreviewStore.myUserId) { sections in
                ForEach(sections.friends.items) { user in
                    SearchFriendRow(user)
                }
            }
        }
    }
}
