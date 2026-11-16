//
//  LocalSearchSections.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 17/11/2026.
//

import Foundation

/// What Recherche's Listes, Ami·es and Groupes find for one query, from what the store holds.
/// Each section is matched when it is read, so a screen showing one pays for one.
struct LocalSearchSections {
    private let allLists: [EntityList]
    private let users: [User]
    private let myGroups: MyGroups
    private let myUserId: String?
    private let query: String
    private let limit: Int

    /// - Parameters:
    ///   - lists: Every list in the store.
    ///   - users: Every reader in the store.
    ///   - myGroups: My groups sorted by my role in each.
    ///   - myUserId: The signed-in reader.
    ///   - query: What the reader typed.
    ///   - limit: How many matches each section shows; `InventorySearchRanking.noLimit` for
    ///     « Tout voir ».
    init(
        lists: [EntityList],
        users: [User],
        myGroups: MyGroups,
        myUserId: String?,
        query: String,
        limit: Int = InventorySearchRanking.displayLimit
    ) {
        self.allLists = lists
        self.users = users
        self.myGroups = myGroups
        self.myUserId = myUserId
        self.query = query
        self.limit = limit
    }

    var lists: LocalSearchMatches<ListSearchMatch> {
        .lists(
            allLists,
            myUserId: myUserId,
            users: users,
            matching: query,
            limit: limit
        )
    }

    var friends: LocalSearchMatches<User> {
        .friends(in: users, matching: query, limit: limit)
    }

    var groups: LocalSearchMatches<ReaderGroup> {
        .groups(in: myGroups, matching: query, limit: limit)
    }
}
