//
//  LocalSearchMatches+Groups.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension LocalSearchMatches where Element == ReaderGroup {
    /// The groups among `myGroups.mine` whose name holds `query`, by name, capped at `limit`.
    ///
    /// - Parameters:
    ///   - myGroups: My groups sorted by my role in each. Only those I belong to are searched.
    ///   - query: What the reader typed.
    ///   - limit: How many groups the section shows; `InventorySearchRanking.noLimit` for
    ///     « Tout voir ».
    /// - Returns: The capped groups, with the uncapped total.
    static func groups(
        in myGroups: MyGroups,
        matching query: String,
        limit: Int = InventorySearchRanking.displayLimit
    ) -> Self {
        matching(query, limit: limit) { text in
            myGroups.mine.filter { $0.name.localizedStandardContains(text) }
        }
    }
}
