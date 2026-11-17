//
//  LocalSearchMatches+Lists.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension LocalSearchMatches where Element == ListSearchMatch {
    /// My lists and my friends' among `lists` whose name holds `query`, mine first, capped at
    /// `limit`.
    ///
    /// - Parameters:
    ///   - lists: Every list in the store.
    ///   - myUserId: The signed-in reader.
    ///   - users: Every reader in the store. Only my friends' lists are kept.
    ///   - query: What the reader typed.
    ///   - limit: How many lists the section shows; `InventorySearchRanking.noLimit` for
    ///     « Tout voir ».
    /// - Returns: The capped lists, with the uncapped total.
    static func lists(
        _ lists: [EntityList],
        myUserId: String?,
        users: [User],
        matching query: String,
        limit: Int = InventorySearchRanking.displayLimit
    ) -> Self {
        matching(query, limit: limit) { text in
            let sections: ListsTabSections = .init(
                lists: lists,
                myUserId: myUserId,
                friends: users.filter(\.isStoredFriend),
                searchText: text
            )
            let mine: [ListSearchMatch] = sections.mine.map { .init(list: $0, owner: nil) }
            let network: [ListSearchMatch] = sections.network.map { .init(list: $0.list, owner: $0.owner) }
            return mine + network
        }
    }
}
