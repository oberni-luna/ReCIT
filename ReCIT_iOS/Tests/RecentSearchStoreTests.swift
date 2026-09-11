//
//  RecentSearchStoreTests.swift
//  ReCIT_iOSTests
//
//  The history the search field writes, checked through the store's public surface with a
//  `UserDefaults` of its own per test — never `.standard`, which the running app writes to and
//  which would leak one case's searches into the next.
//
//  Three of these cases are the reason the store exists in this shape rather than as an array in
//  a view: a phone shared by two accounts owes the second one its own history, a history has to
//  survive the process that wrote it, and two spellings of the same title are one search.
//  All three are launch- or keyboard-shaped failures, the kind nobody reproduces by hand twice.
//
//  See PRD 0012 and issue 0072.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("RecentSearchStore")
@MainActor
struct RecentSearchStoreTests {

    private let alice: String = "usr:alice"
    private let bob: String = "usr:bob"

    /// A defaults domain nobody else writes to, torn down with the test.
    private func makeDefaults() throws -> UserDefaults {
        let suiteName: String = "RecentSearchStoreTests.\(UUID().uuidString)"
        let defaults: UserDefaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        return try #require(UserDefaults(suiteName: suiteName))
    }

    @Test("An account that has never searched has no history")
    func emptyAtFirst() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        #expect(store.searches(userId: alice).isEmpty)
        #expect(store.recentSearches(userId: alice).isEmpty)
    }

    @Test("A search that was sent comes back")
    func aRecordedSearchComesBack() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        store.record(query: "monte cristo", userId: alice)

        #expect(store.recentSearches(userId: alice) == ["monte cristo"])
    }

    @Test("A query that was never sent leaves nothing")
    func nothingIsStoredWithoutARecord() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        // Typing is not submitting: the only way in is `record`, and the screen calls it on
        // submit alone.
        #expect(store.searches(userId: alice).isEmpty)

        // And a query that is nothing but whitespace was never a search either.
        store.record(query: "   ", userId: alice)

        #expect(store.searches(userId: alice).isEmpty)
    }

    @Test("The most recent search comes first")
    func mostRecentFirst() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        store.record(query: "zola", userId: alice)
        store.record(query: "monte cristo", userId: alice)

        #expect(store.recentSearches(userId: alice) == ["monte cristo", "zola"])
    }

    @Test("A second account on the same phone keeps its own history")
    func twoUsersStaySeparate() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        store.record(query: "monte cristo", userId: alice)

        #expect(store.searches(userId: bob).isEmpty)
    }

    @Test("A history survives the launch that wrote it")
    func historySurvivesANewStore() throws {
        let defaults: UserDefaults = try makeDefaults()
        let firstLaunch: RecentSearchStore = .init(defaults: defaults)

        firstLaunch.record(query: "zola", userId: alice)
        firstLaunch.record(query: "monte cristo", userId: alice)

        let nextLaunch: RecentSearchStore = .init(defaults: defaults)
        #expect(nextLaunch.recentSearches(userId: alice) == ["monte cristo", "zola"])
        // And still only for the account that searched.
        #expect(nextLaunch.searches(userId: bob).isEmpty)
    }

    @Test("Searching the same thing twice moves the entry rather than duplicating it")
    func aRepeatMovesToTheFront() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        store.record(query: "zola", userId: alice)
        store.record(query: "monte cristo", userId: alice)
        store.record(query: "zola", userId: alice)

        #expect(store.searches(userId: alice) == ["zola", "monte cristo"])
    }

    @Test("Case and accents fold together into one entry")
    func caseAndAccentsFold() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        store.record(query: "monte cristo", userId: alice)
        store.record(query: "Émile Zola", userId: alice)
        store.record(query: "Monte Cristo", userId: alice)
        store.record(query: "emile zola", userId: alice)

        // Two searches, not four — and each carrying the spelling last typed.
        #expect(store.searches(userId: alice) == ["emile zola", "Monte Cristo"])
    }

    @Test("Whitespace around and inside a query does not make a second entry")
    func whitespaceIsNormalised() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        store.record(query: "  monte   cristo ", userId: alice)

        #expect(store.searches(userId: alice) == ["monte cristo"])

        store.record(query: "monte cristo", userId: alice)

        #expect(store.searches(userId: alice) == ["monte cristo"])
    }

    @Test("Everything sent is stored; only what the screen shows is capped")
    func storageIsNotCapped() throws {
        let store: RecentSearchStore = .init(defaults: try makeDefaults())

        for query in ["un", "deux", "trois", "quatre", "cinq"] {
            store.record(query: query, userId: alice)
        }

        #expect(store.searches(userId: alice).count == 5)
        #expect(store.recentSearches(userId: alice) == ["cinq", "quatre", "trois"])
    }

    @Test("« Effacer » empties one account without touching the other")
    func clearingIsPerAccount() throws {
        let defaults: UserDefaults = try makeDefaults()
        let store: RecentSearchStore = .init(defaults: defaults)
        store.record(query: "monte cristo", userId: alice)
        store.record(query: "zola", userId: bob)

        store.clear(userId: alice)

        #expect(store.searches(userId: alice).isEmpty)
        #expect(store.searches(userId: bob) == ["zola"])
        // Written through, not just forgotten in memory.
        let nextLaunch: RecentSearchStore = .init(defaults: defaults)
        #expect(nextLaunch.searches(userId: alice).isEmpty)
        #expect(nextLaunch.searches(userId: bob) == ["zola"])
    }
}
