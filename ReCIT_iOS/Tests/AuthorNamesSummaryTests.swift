//
//  AuthorNamesSummaryTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 04/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct AuthorNamesSummaryTests {
    @Test
    func `shows nothing for no names`() {
        let summary: AuthorNamesSummary = .init([])

        #expect(summary.shownNames.isEmpty)
        #expect(summary.hiddenCount == 0)
        #expect(summary.text.isEmpty)
    }

    @Test
    func `shows a single name as it is`() {
        let summary: AuthorNamesSummary = .init(["Greta Thunberg"])

        #expect(summary.shownNames == ["Greta Thunberg"])
        #expect(summary.hiddenCount == 0)
        #expect(summary.text == "Greta Thunberg")
    }

    @Test
    func `joins three names with commas and hides none`() {
        let summary: AuthorNamesSummary = .init(["A", "B", "C"])

        #expect(summary.shownNames == ["A", "B", "C"])
        #expect(summary.hiddenCount == 0)
        #expect(summary.text == "A, B, C")
    }

    @Test
    func `keeps the first three of four names and counts one hidden`() {
        let summary: AuthorNamesSummary = .init(["A", "B", "C", "D"])

        #expect(summary.shownNames == ["A", "B", "C"])
        #expect(summary.hiddenCount == 1)
        #expect(summary.text.hasPrefix("A, B, C "))
        #expect(summary.text.contains("D") == false)
    }

    @Test
    func `keeps the first three of 101 names in their order and counts 98 hidden`() {
        let names: [String] = ["Greta Thunberg", "Peter Brannen", "Beth Shapiro"]
            + (4...101).map { "Author \($0)" }

        let summary: AuthorNamesSummary = .init(names)

        #expect(summary.shownNames == ["Greta Thunberg", "Peter Brannen", "Beth Shapiro"])
        #expect(summary.hiddenCount == 98)
        #expect(summary.text.hasPrefix("Greta Thunberg, Peter Brannen, Beth Shapiro "))
        #expect(summary.text.contains("98"))
    }
}
