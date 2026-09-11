//
//  InventorySearchRankingTests.swift
//  ReCIT_iOSTests
//
//  Which three books the merged search section shows, in which order, and how many it found in
//  all. No `ModelContainer` and no network: the ranking works over values precisely so this
//  suite can drive it with four books and a clock made of dates.
//
//  The accent case is the one that used to be a bug report rather than a test — « emile zola »
//  finding « Émile Zola » is why the app matches with `localizedStandardContains` everywhere a
//  user types.
//
//  See PRD 0012.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("InventorySearchRanking")
struct InventorySearchRankingTests {

    private typealias Candidate = InventorySearchRanking.Candidate

    /// Days ago, so "most recently added" reads as it does on screen.
    private func daysAgo(_ days: Int) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000).addingTimeInterval(-Double(days) * 86_400)
    }

    private func candidate(
        _ id: String,
        _ searchIndex: String,
        isMine: Bool,
        daysAgo days: Int
    ) -> Candidate {
        .init(
            id: id,
            searchIndex: searchIndex,
            isMine: isMine,
            created: daysAgo(days)
        )
    }

    /// Four copies of the same book: two mine, two a friend's, each pair added on
    /// different days.
    private var library: [Candidate] {
        [
            candidate("mine-old", "Le Comte de Monte-Cristo Alexandre Dumas", isMine: true, daysAgo: 30),
            candidate("friend-recent", "Le Comte de Monte-Cristo Alexandre Dumas camille", isMine: false, daysAgo: 1),
            candidate("mine-recent", "Monte-Cristo, tome 2 Alexandre Dumas", isMine: true, daysAgo: 2),
            candidate("friend-old", "Monte-Cristo, tome 3 Alexandre Dumas rené", isMine: false, daysAgo: 40),
            candidate("unrelated", "Germinal Émile Zola", isMine: true, daysAgo: 3)
        ]
    }

    // MARK: - The cap

    @Test("The section never shows more than three books, and still says how many there are")
    func capsAtThreeAndReportsTheTotal() {
        let outcome: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "monte"
        )

        #expect(outcome.matches.count == 3)
        #expect(outcome.totalCount == 4)
    }

    @Test("Below the cap, the section shows everything it found")
    func underTheCapNothingIsHidden() {
        let outcome: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "germinal"
        )

        #expect(outcome.matches.map(\.id) == ["unrelated"])
        #expect(outcome.totalCount == 1)
    }

    @Test("« Tout voir » asks the same function for everything, and gets the same order")
    func noLimitReturnsEveryMatch() {
        let capped: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "monte"
        )
        let full: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "monte",
            limit: InventorySearchRanking.noLimit
        )

        #expect(full.matches.count == full.totalCount)
        #expect(full.totalCount == capped.totalCount)
        // The screen behind « Tout voir » opens on the three books the section was showing,
        // in the order it was showing them, and carries on from there.
        #expect(full.matches.prefix(capped.matches.count).map(\.id) == capped.matches.map(\.id))
    }

    // MARK: - The order

    @Test("My books come before my friends', most recently added first inside each group")
    func mineComeFirstThenMostRecent() {
        let outcome: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "monte",
            limit: 10
        )

        #expect(outcome.matches.map(\.id) == ["mine-recent", "mine-old", "friend-recent", "friend-old"])
    }

    @Test("A friend's copy is never pushed above one of mine by being newer")
    func aNewerFriendCopyStaysBelowMine() {
        let outcome: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "monte"
        )

        #expect(outcome.matches.map(\.isMine) == [true, true, false])
    }

    // MARK: - Matching

    @Test("Case and accents are ignored: « emile zola » finds « Émile Zola »")
    func caseAndAccentsAreIgnored() {
        let outcome: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "emile zola"
        )

        #expect(outcome.matches.map(\.id) == ["unrelated"])
        #expect(outcome.totalCount == 1)
    }

    @Test("The owner's name in the index is searchable, so a friend can be looked up by name")
    func theOwnerNameIsSearchable() {
        let outcome: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "RENÉ"
        )

        #expect(outcome.matches.map(\.id) == ["friend-old"])
    }

    // MARK: - Nothing to show

    @Test("An empty query matches nothing rather than everything")
    func anEmptyQueryMatchesNothing() {
        #expect(InventorySearchRanking.rank(library, matching: "") == .none)
        #expect(InventorySearchRanking.rank(library, matching: "   ") == .none)
    }

    @Test("A query nobody owns comes back empty, with a total of zero")
    func aQueryMatchingNothingComesBackEmpty() {
        let outcome: InventorySearchRanking.Outcome = InventorySearchRanking.rank(
            library,
            matching: "proust"
        )

        #expect(outcome.matches.isEmpty)
        #expect(outcome.totalCount == 0)
    }

    @Test("An empty library answers an honest question with an empty section")
    func anEmptyLibraryComesBackEmpty() {
        #expect(InventorySearchRanking.rank([], matching: "monte") == .none)
    }
}
