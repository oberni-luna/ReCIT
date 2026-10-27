//
//  EditionDuplicateDetectorTests.swift
//  ReCIT_iOSTests
//
//  Which editions of one work « Éditions » shows as duplicates, and which one of a pair it
//  proposes to keep. PRD 0028, rules 1 to 7.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("Edition duplicate detection")
struct EditionDuplicateDetectorTests {

    // MARK: - Fixtures

    private func inv(
        _ id: String,
        isbn: String? = nil,
        publisher: String? = nil,
        year: String? = nil,
        differentFrom: Set<String> = [],
        reported: Set<String> = [],
        completeness: Int = 0
    ) -> EditionFacts {
        .init(
            uri: "inv:\(id)",
            mergeUri: "inv:\(id)",
            isbn: isbn,
            publisherUri: publisher,
            year: year,
            differentFrom: differentFrom,
            reportedMergeTargets: reported,
            completeness: completeness
        )
    }

    private func wd(_ id: String, isbn: String? = nil, completeness: Int = 0) -> EditionFacts {
        .init(uri: "wd:\(id)", mergeUri: nil, isbn: isbn, completeness: completeness)
    }

    // MARK: - Rules

    @Test("Two editions with the same ISBN are « Même ISBN »")
    func sameIsbn() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8"),
            inv("B", isbn: "9782070368228")
        ])

        #expect(result.pairs.map(\.reason) == [.sameIsbn])
        #expect(result.tags == ["inv:A": .sameIsbn, "inv:B": .sameIsbn])
    }

    @Test("An ISBN-10 and its ISBN-13 are the same ISBN")
    func tenAndThirteen() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "2-07-036822-X"),
            inv("B", isbn: "978-2-07-036822-8")
        ])

        #expect(result.pairs.map(\.reason) == [.sameIsbn])
    }

    @Test("No ISBN on one side, same publisher and same year: « Doublon probable »")
    func probable() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8", publisher: "wd:Gallimard", year: "1998"),
            inv("B", publisher: "wd:Gallimard", year: "1998")
        ])

        #expect(result.pairs.map(\.reason) == [.probable])
        #expect(result.tags == ["inv:A": .probable, "inv:B": .probable])
    }

    @Test("No ISBN on either side, same publisher and same year: still « Doublon probable »")
    func probableWithoutAnyIsbn() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", publisher: "wd:Gallimard", year: "1998"),
            inv("B", publisher: "wd:Gallimard", year: "1998")
        ])

        #expect(result.pairs.map(\.reason) == [.probable])
    }

    @Test("Another publisher, another year, or no publisher at all: no duplicate")
    func notProbable() {
        let otherPublisher: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", publisher: "wd:Gallimard", year: "1998"),
            inv("B", publisher: "wd:Poche", year: "1998")
        ])
        let otherYear: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", publisher: "wd:Gallimard", year: "1998"),
            inv("B", publisher: "wd:Gallimard", year: "1999")
        ])
        let unknown: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", year: "1998"),
            inv("B", year: "1998")
        ])

        #expect(otherPublisher == .none)
        #expect(otherYear == .none)
        #expect(unknown == .none)
    }

    @Test("Two different ISBNs never make a duplicate, even with the same publisher and year")
    func differentIsbns() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8", publisher: "wd:Gallimard", year: "1998"),
            inv("B", isbn: "978-0-19-853453-2", publisher: "wd:Gallimard", year: "1998")
        ])

        #expect(result == .none)
    }

    @Test("Two Wikidata editions are not proposed: neither can be merged from")
    func twoWikidata() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            wd("Q1", isbn: "978-2-07-036822-8"),
            wd("Q2", isbn: "978-2-07-036822-8")
        ])

        #expect(result == .none)
    }

    @Test("A Wikidata and an inventaire.io edition are proposed")
    func wikidataAndInv() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            wd("Q1", isbn: "978-2-07-036822-8"),
            inv("A", isbn: "978-2-07-036822-8")
        ])

        #expect(result.pairs.count == 1)
    }

    @Test("A pair declared different, in either direction, is not proposed")
    func declaredDifferent() {
        let oneWay: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8", differentFrom: ["inv:B"]),
            inv("B", isbn: "978-2-07-036822-8")
        ])
        let otherWay: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8"),
            inv("B", isbn: "978-2-07-036822-8", differentFrom: ["inv:A"])
        ])
        let againstWikidata: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8", differentFrom: ["wd:Q1"]),
            wd("Q1", isbn: "978-2-07-036822-8")
        ])

        #expect(oneWay == .none)
        #expect(otherWay == .none)
        #expect(againstWikidata == .none)
    }

    @Test("A pair with an open merge task is « Doublon signalé » and not proposed")
    func reported() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8", reported: ["wd:Q1"]),
            wd("Q1", isbn: "978-2-07-036822-8")
        ])

        #expect(result.pairs.isEmpty)
        #expect(result.tags == ["inv:A": .reported, "wd:Q1": .reported])
    }

    @Test("Three editions with one ISBN are two pairs, not three")
    func groupOfThree() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8"),
            inv("B", isbn: "978-2-07-036822-8"),
            inv("C", isbn: "978-2-07-036822-8")
        ])

        #expect(result.pairs.count == 2)
        #expect(Set(result.pairs.flatMap { [$0.first.uri, $0.second.uri] }) == ["inv:A", "inv:B", "inv:C"])
    }

    @Test("An edition between two different ISBNs never pairs those two")
    func bridgeDoesNotPairDifferentIsbns() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8", publisher: "wd:Gallimard", year: "1998"),
            inv("B", publisher: "wd:Gallimard", year: "1998"),
            inv("C", isbn: "978-0-19-853453-2", publisher: "wd:Gallimard", year: "1998")
        ])

        #expect(result.pairs.count == 2)
        #expect(result.pairs.allSatisfy { $0.contains("inv:B") })
    }

    @Test("« Même ISBN » pairs come first, and win over « Doublon probable » on a shared edition")
    func sameIsbnFirst() {
        let result: EditionDuplicates = EditionDuplicateDetector.detect([
            inv("A", isbn: "978-2-07-036822-8", publisher: "wd:Gallimard", year: "1998"),
            inv("B", isbn: "978-2-07-036822-8"),
            inv("C", publisher: "wd:Gallimard", year: "1998")
        ])

        #expect(result.pairs.map(\.reason) == [.sameIsbn, .probable])
        #expect(result.tags["inv:A"] == .sameIsbn)
        #expect(result.tags["inv:C"] == .probable)
    }

    @Test("The signature does not depend on the order the editions come in")
    func signatureIsStable() {
        let editions: [EditionFacts] = [
            inv("A", isbn: "978-2-07-036822-8"),
            inv("B", isbn: "978-2-07-036822-8")
        ]

        #expect(EditionDuplicateDetector.detect(editions).signature == EditionDuplicateDetector.detect(editions.reversed()).signature)
        #expect(EditionDuplicates.none.signature.isEmpty)
    }

    // MARK: - Which one is kept

    @Test("A Wikidata edition is always kept, and the other cannot be")
    func wikidataIsKept() {
        let pair: EditionDuplicatePair = .init(
            first: inv("A", isbn: "978-2-07-036822-8", completeness: 7),
            second: wd("Q1", isbn: "978-2-07-036822-8", completeness: 1),
            reason: .sameIsbn
        )

        #expect(MergeChoice.proposedKeep(in: pair).uri == "wd:Q1")
        #expect(MergeChoice.canKeep(pair.first, in: pair) == false)
        #expect(MergeChoice.request(keeping: pair.second, in: pair) == .init(from: "inv:A", to: "wd:Q1"))
        #expect(MergeChoice.request(keeping: pair.first, in: pair) == nil)
    }

    @Test("Between two inventaire.io editions, the more complete one is proposed, then the more copies")
    func mostCompleteIsKept() {
        let complete: EditionDuplicatePair = .init(
            first: inv("A", completeness: 2),
            second: inv("B", completeness: 5),
            reason: .probable
        )
        let tied: EditionDuplicatePair = .init(
            first: inv("A", completeness: 3),
            second: inv("B", completeness: 3),
            reason: .probable
        )

        #expect(MergeChoice.proposedKeep(in: complete).uri == "inv:B")
        #expect(MergeChoice.proposedKeep(in: tied, copyCounts: ["inv:B": 3, "inv:A": 1]).uri == "inv:B")
        #expect(MergeChoice.proposedKeep(in: tied).uri == "inv:A")
        #expect(MergeChoice.canKeep(complete.first, in: complete))
        #expect(MergeChoice.request(keeping: complete.first, in: complete) == .init(from: "inv:B", to: "inv:A"))
    }

    @Test("Completeness counts one point per datum the edition carries")
    @MainActor
    func completenessOfAnEdition() {
        let bare: Edition = .init(uri: "inv:A", title: "T", lang: nil, authorNames: [])
        let rich: Edition = .init(uri: "inv:B", title: "T", subtitle: "S", lang: "fr", authorNames: [], image: "https://x/y.jpg")
        rich.isbn = "978-2-07-036822-8"
        rich.numberOfPages = 542
        rich.publisherUri = "wd:Gallimard"
        rich.publicationDate = "1998"

        #expect(EditionFacts(edition: bare).completeness == 0)
        #expect(EditionFacts(edition: rich).completeness == 7)
        #expect(EditionFacts(edition: rich).mergeUri == "inv:B")
        #expect(EditionFacts(edition: rich).isbn == "9782070368228")
    }
}
