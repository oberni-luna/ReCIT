//
//  EditionTitleTests.swift
//  ReCIT_iOSTests
//
//  The name an edition wears, and the three places inventaire.io can be keeping it.
//
//  `mulLabelIsRead` is the case this type was written for. Editions mirrored from Wikidata carry
//  their title under the multilingual `mul` label rather than under the `fromclaims` one
//  inventaire.io synthesises for its own entities — `wd:Q137643134` is called *Dune* — and
//  reading only `fromclaims` is what drew 13 % of a work's editions as `Unknown`.
//
//  See PRD 0014.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("EditionTitle")
struct EditionTitleTests {

    private func titleClaim(_ value: String) -> [String: [ClaimValue]] {
        [WikidataProperty.title.rawValue: [.string(value)]]
    }

    @Test("inventaire.io's own label comes first")
    func fromclaimsWins() {
        let title: String? = EditionTitle.resolve(
            labels: ["fromclaims": "Dune, Tome 1", "mul": "Dune"],
            claims: titleClaim("Dune")
        )

        #expect(title == "Dune, Tome 1")
    }

    @Test("A Wikidata edition is named by its mul label, not by Unknown")
    func mulLabelIsRead() {
        // The shape of `wd:Q137643134`, verified against production on 2026-09-11.
        let title: String? = EditionTitle.resolve(
            labels: ["mul": "Dune"],
            claims: titleClaim("Dune")
        )

        #expect(title == "Dune")
    }

    @Test("With no label at all, the claim answers")
    func claimIsTheLastSpelling() {
        #expect(EditionTitle.resolve(labels: [:], claims: titleClaim("Dune")) == "Dune")
        #expect(EditionTitle.resolve(labels: nil, claims: titleClaim("Dune")) == "Dune")
    }

    @Test("An edition with none of the three has no name")
    func namelessResolvesToNil() {
        #expect(EditionTitle.resolve(labels: [:], claims: [:]) == nil)
        #expect(EditionTitle.resolve(labels: nil, claims: nil) == nil)
    }

    @Test("An empty spelling is not a name, and the next one is tried")
    func emptyStringsFallThrough() {
        let title: String? = EditionTitle.resolve(
            labels: ["fromclaims": "", "mul": ""],
            claims: titleClaim("Dune")
        )

        #expect(title == "Dune")
        #expect(EditionTitle.resolve(labels: ["fromclaims": ""], claims: [:]) == nil)
    }

    @Test("A label under some other language is not a title")
    func unrelatedLabelsAreIgnored() {
        // `fr` and `en` are where a *work* keeps its label. An edition that has neither of the
        // three spellings has no name, and saying otherwise would let the ladder redirect onto
        // something the screen cannot draw.
        #expect(EditionTitle.resolve(labels: ["fr": "Dune"], claims: [:]) == nil)
    }
}
