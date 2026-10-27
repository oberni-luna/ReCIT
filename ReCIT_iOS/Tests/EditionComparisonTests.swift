//
//  EditionComparisonTests.swift
//  ReCIT_iOSTests
//
//  « Ce qui diffère » between the two editions of a duplicate pair, and « Pareil : … ». PRD 0028.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("Edition comparison")
struct EditionComparisonTests {

    @Test("What differs is listed with both values, the rest is « Pareil »")
    func differencesAndSame() {
        let comparison: EditionComparison = .init(
            first: .init(title: "Tome 1", isbn: "978-2-07-036822-8", publisher: "Gallimard", pages: 542, hasCover: true, language: "fr", workUris: ["wd:W1"]),
            second: .init(title: "Tome 1 bis", isbn: "2-07-036822-X", publisher: "Gallimard", hasCover: false, language: "fr", workUris: ["wd:W1"])
        )

        #expect(comparison.differences == [
            .init(property: .title, first: "Tome 1", second: "Tome 1 bis"),
            .init(property: .pages, first: "542", second: nil),
            .init(property: .cover, first: "yes", second: "no")
        ])
        #expect(comparison.sameProperties == [.isbn, .publisher, .publicationDate, .language, .work])
    }

    @Test("A value one edition lacks differs from the other's")
    func missingValueDiffers() {
        let comparison: EditionComparison = .init(
            first: .init(title: "T", publicationDate: "1995"),
            second: .init(title: "T")
        )

        #expect(comparison.differences == [.init(property: .publicationDate, first: "1995", second: nil)])
    }

    @Test("A missing value reads « — », a cover in words")
    func values() {
        #expect(EditionDifferencesSection.values(of: .init(property: .pages, first: "542", second: nil)) == "542  ·  —")
    }
}
