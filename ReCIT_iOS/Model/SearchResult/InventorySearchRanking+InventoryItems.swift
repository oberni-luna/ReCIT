//
//  InventorySearchRanking+InventoryItems.swift
//  ReCIT_iOS
//
//  The one place a pile of `InventoryItem`s becomes a ranked answer to a query.
//
//  `InventorySearchRanking` works over plain values so it can be tested without a
//  `ModelContainer`, which leaves someone to turn the copies on screen into those values and
//  the ids back into copies. That translation used to live inside the capped section; « Tout
//  voir » gave it a second caller (issue 0075), and two copies of it would have been two
//  chances for the section and the screen behind it to disagree about which book comes first.
//  It lives here instead, and both ask for the same thing with a different `limit`.
//
//  A copy whose row has gone — deleted while the list was still on screen — is dropped before
//  any of its properties are read: reading a persisted property off an invalidated model is a
//  hard trap, not a nil. See `PersistentModel+StillInTheStore` and issue 0065.
//
//  See PRD 0012.
//

import Foundation

extension InventorySearchRanking {
    /// What a screen draws: the copies themselves, in the ranking's order, and how many
    /// matched before `limit` was applied. The count is what tells the capped section whether
    /// « Tout voir » has anything more to lead to.
    struct ItemOutcome {
        let items: [InventoryItem]
        let totalCount: Int

        static let none: ItemOutcome = .init(items: [], totalCount: 0)
    }

    /// The copies among `items` that answer `query`, mine first and most recently added first
    /// within each group, capped at `limit` — with the uncapped total alongside.
    ///
    /// Pass `noLimit` for the full listing; the default is what the inventory search section
    /// shows.
    static func rankItems(
        _ items: [InventoryItem],
        matching query: String,
        ownerId: String,
        limit: Int = displayLimit
    ) -> ItemOutcome {
        let live: [InventoryItem] = items.filter(\.isStillInTheStore)
        guard !live.isEmpty else { return .none }

        let byId: [String: InventoryItem] = .init(
            live.map { ($0._id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let candidates: [Candidate] = live.map { item in
            .init(
                id: item._id,
                searchIndex: item.searchIndex,
                isMine: item.ownerId == ownerId,
                created: item.created
            )
        }
        let outcome: Outcome = rank(
            candidates,
            matching: query,
            limit: limit
        )

        return .init(
            items: outcome.matches.compactMap { byId[$0.id] },
            totalCount: outcome.totalCount
        )
    }
}
