//
//  InventorySearchRanking.swift
//  ReCIT_iOS
//
//  Which books already on this device answer a query, in which order, and how many there are
//  in all. The inventory screen's search shows my copies and my friends' copies in one section
//  capped at three, and this is the type that decides what those three are.
//
//  It works over `Candidate` — an id, a search index, whether the book is mine and when it was
//  added — rather than over `InventoryItem`, so it can be tested without standing up a
//  `ModelContainer`. The screen builds candidates from the `@Query`-backed items it already
//  has, so ADR 0001's reactivity is untouched: nothing is fetched twice, nothing is persisted,
//  and this type never sees the store.
//
//  Two decisions are worth stating:
//
//  1. **The total comes back alongside the capped three.** The cap is a display rule, not a
//     search rule, and the count is what will decide whether « Tout voir » appears (issue
//     0075). Discarding it here would mean searching twice to get it back.
//  2. **Mine before my friends'.** The first question this section answers is "do I already own
//     this?", so a copy of my own is never pushed under the cap by a friend's.
//
//  See PRD 0012.
//

import Foundation

enum InventorySearchRanking {
    /// A book reduced to what ranking needs. `searchIndex` is the same string
    /// `InventoryItem` builds at sync — title, subtitle, authors, owner.
    struct Candidate: Equatable, Identifiable, Sendable {
        let id: String
        let searchIndex: String
        let isMine: Bool
        let created: Date

        init(
            id: String,
            searchIndex: String,
            isMine: Bool,
            created: Date
        ) {
            self.id = id
            self.searchIndex = searchIndex
            self.isMine = isMine
            self.created = created
        }
    }

    /// What the section shows, and what it would have shown without the cap.
    struct Outcome: Equatable, Sendable {
        /// The matches the section displays, at most `displayLimit` of them.
        let matches: [Candidate]
        /// Every match, counted before the cap.
        let totalCount: Int

        static let none: Outcome = .init(matches: [], totalCount: 0)
    }

    /// How many matches the section shows. Three, because the keyboard covers everything below
    /// roughly 516 pt and a fourth row would push the road to inventaire.io under it.
    static let displayLimit: Int = 3

    /// No cap at all — what « Tout voir » asks for (issue 0075). The screen behind that action
    /// lists every match, and it asks this same function for them rather than sorting by hand:
    /// a second ordering would be a second chance for the full list and the capped section to
    /// disagree about which book comes first.
    static let noLimit: Int = .max

    /// The matches for `query`, mine first and most recently added first within each group,
    /// capped at `limit` — with the uncapped total alongside.
    ///
    /// An empty (or whitespace-only) query matches nothing rather than everything: this section
    /// exists to answer a question that has been asked, and the screen has other things to show
    /// before one has been.
    static func rank(
        _ candidates: [Candidate],
        matching query: String,
        limit: Int = displayLimit
    ) -> Outcome {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }

        // `localizedStandardContains` is the app's matching rule everywhere a user types:
        // case- and diacritic-insensitive, so « emile zola » finds « Émile Zola ».
        let matches: [Candidate] = candidates
            .filter { $0.searchIndex.localizedStandardContains(trimmed) }
            .sorted { first, second in
                if first.isMine != second.isMine { return first.isMine }
                return first.created > second.created
            }

        return .init(
            matches: Array(matches.prefix(max(limit, 0))),
            totalCount: matches.count
        )
    }
}
