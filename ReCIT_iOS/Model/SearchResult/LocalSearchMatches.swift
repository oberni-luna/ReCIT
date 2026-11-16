//
//  LocalSearchMatches.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

/// What one of Recherche's local sections — Listes, Ami·es, Groupes — shows for a query: its
/// first matches, and how many matched in all. A blank query matches nothing, the cap is applied
/// after matching, and the uncapped total says whether « Tout voir » has more to show.
struct LocalSearchMatches<Element> {
    /// The matches the section draws, at most the limit it was built with.
    let items: [Element]
    /// Every match, counted before the cap.
    let totalCount: Int

    /// Whether the cap hid at least one match — the section then offers « Tout voir ».
    var isCapped: Bool {
        totalCount > items.count
    }

    /// - Parameters:
    ///   - matches: Every match, already in display order.
    ///   - limit: How many of them the section shows.
    init(
        _ matches: [Element],
        limit: Int
    ) {
        items = Array(matches.prefix(max(limit, 0)))
        totalCount = matches.count
    }

    /// The matches `find` returns for `query`, capped at `limit`.
    ///
    /// - Parameters:
    ///   - query: What the reader typed. Trimmed before `find` sees it; blank matches nothing.
    ///   - limit: How many matches the section shows.
    ///   - find: Every candidate matching the trimmed query, in display order.
    /// - Returns: The capped matches, with the uncapped total.
    static func matching(
        _ query: String,
        limit: Int,
        find: (String) -> [Element]
    ) -> Self {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .init([], limit: limit) }
        return .init(find(trimmed), limit: limit)
    }
}
