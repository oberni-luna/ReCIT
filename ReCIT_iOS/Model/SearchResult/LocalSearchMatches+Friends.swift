//
//  LocalSearchMatches+Friends.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension LocalSearchMatches where Element == User {
    /// My friends among `users` whose username holds `query`, by username, capped at `limit`.
    ///
    /// - Parameters:
    ///   - users: Every reader in the store. Those gone from it, and those who are not my
    ///     friends, are left out.
    ///   - query: What the reader typed.
    ///   - limit: How many friends the section shows; `InventorySearchRanking.noLimit` for
    ///     « Tout voir ».
    /// - Returns: The capped friends, with the uncapped total.
    static func friends(
        in users: [User],
        matching query: String,
        limit: Int = InventorySearchRanking.displayLimit
    ) -> Self {
        matching(query, limit: limit) { text in
            users
                .filter { $0.isStillInTheStore && $0.relation == .friend }
                .filter { $0.username.localizedStandardContains(text) }
                .sorted { lhs, rhs in
                    switch lhs.username.localizedStandardCompare(rhs.username) {
                    case .orderedAscending: true
                    case .orderedDescending: false
                    case .orderedSame: lhs._id < rhs._id
                    }
                }
        }
    }
}
