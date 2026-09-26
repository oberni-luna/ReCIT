//
//  ListCoverPreviewTests.swift
//  ReCIT_iOSTests
//
//  The covers a row of the Lists tab fans out, and the words that count a list's elements.
//  Pure and network-free.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct ListCoverPreviewTests {
    private func item(
        _ uri: String,
        ordinal: String
    ) -> EntityListItem {
        .init(
            _id: "item-\(uri)-\(ordinal)",
            uri: uri,
            ordinal: ordinal,
            created: .now,
            itemType: .work
        )
    }

    @Test
    func takesTheFirstThreeInTheListsOwnOrder() {
        let elements: [EntityListItem] = [
            item("wd:Q4", ordinal: "3"),
            item("wd:Q1", ordinal: "0"),
            item("wd:Q3", ordinal: "2"),
            item("wd:Q2", ordinal: "1"),
        ]

        #expect(ListCoverPreview.uris(of: elements) == ["wd:Q1", "wd:Q2", "wd:Q3"])
    }

    @Test
    func aShortListShowsWhatItHas() {
        let elements: [EntityListItem] = [item("wd:Q1", ordinal: "0")]

        #expect(ListCoverPreview.uris(of: elements) == ["wd:Q1"])
        #expect(ListCoverPreview.uris(of: []).isEmpty)
    }

    @Test
    func aRepeatedElementIsShownOnce() {
        let elements: [EntityListItem] = [
            item("wd:Q1", ordinal: "0"),
            item("wd:Q1", ordinal: "1"),
            item("wd:Q2", ordinal: "2"),
        ]

        #expect(ListCoverPreview.uris(of: elements) == ["wd:Q1", "wd:Q2"])
    }

    @Test(arguments: [
        (EntityListType.work, 1, "1 œuvre"),
        (EntityListType.work, 12, "12 œuvres"),
        (EntityListType.author, 1, "1 auteur·ice"),
        (EntityListType.author, 7, "7 auteur·ices"),
        (EntityListType.publisher, 2, "2 maisons d'édition"),
    ])
    func countIsSaidInFrench(type: EntityListType, count: Int, expected: String) {
        var resource: LocalizedStringResource = type.countLabel(count)
        resource.locale = .init(identifier: "fr")

        #expect(String(localized: resource) == expected)
    }
}
