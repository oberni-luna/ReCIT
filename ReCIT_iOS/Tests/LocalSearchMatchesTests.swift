//
//  LocalSearchMatchesTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct LocalSearchMatchesTests {
    private let names: [String] = ["Anne", "Bea", "Carl", "Dora"]

    @Test
    func `shows three of four matches, counts four, and is capped`() {
        let matches: LocalSearchMatches<String> = .matching("a", limit: InventorySearchRanking.displayLimit) { _ in names }

        #expect(matches.items == ["Anne", "Bea", "Carl"])
        #expect(matches.totalCount == 4)
        #expect(matches.isCapped)
    }

    @Test
    func `shows exactly three matches without being capped`() {
        let matches: LocalSearchMatches<String> = .matching("a", limit: InventorySearchRanking.displayLimit) { _ in
            Array(names.prefix(3))
        }

        #expect(matches.items.count == 3)
        #expect(matches.totalCount == 3)
        #expect(!matches.isCapped)
    }

    @Test
    func `shows every match without a limit`() {
        let matches: LocalSearchMatches<String> = .matching("a", limit: InventorySearchRanking.noLimit) { _ in names }

        #expect(matches.items == names)
        #expect(!matches.isCapped)
    }

    @Test
    func `hands the trimmed query to the matching`() {
        var received: String?
        let matches: LocalSearchMatches<String> = .matching("  bel \n", limit: InventorySearchRanking.displayLimit) { text in
            received = text
            return names
        }

        #expect(received == "bel")
        #expect(matches.totalCount == 4)
    }

    @Test(arguments: ["", "   ", "\n"])
    func `matches nothing for a blank query`(query: String) {
        var asked: Bool = false
        let matches: LocalSearchMatches<String> = .matching(query, limit: InventorySearchRanking.displayLimit) { _ in
            asked = true
            return names
        }

        #expect(!asked)
        #expect(matches.items.isEmpty)
        #expect(matches.totalCount == 0)
    }
}
