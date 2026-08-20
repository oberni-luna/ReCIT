//
//  GenreClaimsTests.swift
//  ReCIT_iOSTests
//
//  The rule that decides what counts as a work's genre. It exists because the original one
//  read `wdt:P136` alone, which inventaire's own works never carry — so a French library
//  answered "no genre anywhere" and the arrangement had nothing to build on. See issue 0034.
//

import Testing
@testable import ReCIT_iOS

@Suite("GenreClaims")
struct GenreClaimsTests {

    @Test("A work with genres uses them and ignores its subjects")
    func genresWin() {
        let uris: [String] = GenreClaims.uris(
            genres: ["wd:Q8261", "wd:Q182357"],
            subjects: ["wd:Q6206"]
        )

        #expect(uris == ["wd:Q8261", "wd:Q182357"])
    }

    /// The case that was reported: an `inv:` work with a main subject and no genre at all.
    @Test("A work with no genre falls back to its subjects")
    func subjectsAreTheFallback() {
        let uris: [String] = GenreClaims.uris(
            genres: [],
            subjects: ["wd:Q4825937", "wd:Q6206"]
        )

        #expect(uris == ["wd:Q4825937", "wd:Q6206"])
    }

    @Test("A work with neither yields nothing")
    func bareWorkYieldsNothing() {
        #expect(GenreClaims.uris(genres: [], subjects: []).isEmpty)
    }

    /// Pooling the two would let a work with a real genre be pulled towards a theme, which is
    /// a regression for the half of the library that already worked.
    @Test("Genres and subjects are never mixed into one list")
    func theTwoAreNeverPooled() {
        let uris: [String] = GenreClaims.uris(genres: ["wd:Q8261"], subjects: ["wd:Q6206"])

        #expect(uris.contains("wd:Q6206") == false)
    }

    @Test("Repeated uris are collapsed, in the order they arrived")
    func duplicatesCollapse() {
        let uris: [String] = GenreClaims.uris(
            genres: ["wd:Q8261", "wd:Q182357", "wd:Q8261"],
            subjects: []
        )

        #expect(uris == ["wd:Q8261", "wd:Q182357"])
    }

    @Test("Duplicates are collapsed on the fallback path too")
    func duplicatesCollapseInSubjects() {
        let uris: [String] = GenreClaims.uris(
            genres: [],
            subjects: ["wd:Q6206", "wd:Q6206"]
        )

        #expect(uris == ["wd:Q6206"])
    }

    /// The properties are read from `WikidataProperty` rather than spelled out twice, and the
    /// revision is what re-asks works stamped under the old rule.
    @Test("The claim identifiers and the revision are the ones the backfill reads")
    func identifiers() {
        #expect(GenreClaims.genreProperty == "wdt:P136")
        #expect(GenreClaims.subjectProperty == "wdt:P921")
        #expect(GenreClaims.revision > 1)
    }
}
