//
//  GenreClaimsTests.swift
//  ReCIT_iOSTests
//
//  The rule that decides what counts as a work's genre. It exists because the original one
//  read `wdt:P136` alone, which inventaire's own works never carry — so a French library
//  answered "no genre anywhere" and the arrangement had nothing to build on. See issue 0034.
//
//  And the rule that decides whether a work still has to be asked about at all, which the book
//  screen leans on to fetch one work on appear without ever fetching it twice. See issue 0035.
//

import Foundation
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

    // MARK: - Does this work still need asking

    // The decision behind both fetch paths: the backfill's filter, and the single-work fetch the
    // book screen makes on appear (issue 0035). Pinned here because the book-screen path is the
    // one that is invisible when it is wrong — asking every time looks exactly like asking once
    // on a fast connection, and quietly costs two requests for every book opened.

    @Test("A work never asked about needs asking")
    func neverAskedNeedsAsking() {
        #expect(GenreClaims.needsAsking(enrichedAt: nil, revision: 0))
    }

    /// A missing timestamp wins outright: a work carrying the current revision but no timestamp
    /// was never actually asked.
    @Test("A work never asked about needs asking whatever its revision says")
    func neverAskedWinsOverTheRevision() {
        #expect(GenreClaims.needsAsking(enrichedAt: nil, revision: GenreClaims.revision))
    }

    /// This is what stops the book screen fetching the same work on every visit.
    @Test("A work asked under the current rule does not need asking again")
    func askedUnderTheCurrentRuleIsDone() {
        #expect(GenreClaims.needsAsking(enrichedAt: .now, revision: GenreClaims.revision) == false)
    }

    /// The case issue 0034 turned on: stamped, but under the genre-only reading of the claims.
    @Test("A work asked under an older rule needs asking again")
    func anOlderRevisionNeedsAsking() {
        #expect(GenreClaims.needsAsking(enrichedAt: .now, revision: GenreClaims.revision - 1))
    }

    /// A work stored before the marker existed reads as revision 0.
    @Test("A work stored before the revision marker existed needs asking again")
    func aWorkFromBeforeTheMarkerNeedsAsking() {
        #expect(GenreClaims.needsAsking(enrichedAt: .now, revision: 0))
    }

    /// Ahead of the app rather than behind it — a store written by a newer build, then opened by
    /// an older one. Nothing to re-ask: the answer is at least as good as this build's rule.
    @Test("A work asked under a newer rule is left alone")
    func aNewerRevisionIsLeftAlone() {
        #expect(GenreClaims.needsAsking(enrichedAt: .now, revision: GenreClaims.revision + 1) == false)
    }

    /// The empty answer is an answer. Wikidata simply has no genre for many French mid-list
    /// titles, and re-asking those on every visit is the cost this marker exists to avoid.
    @Test("A work asked and found to have nothing does not need asking again")
    func anEmptyAnswerCounts() {
        let work: Work = .init(uri: "inv:sans-genre", lastrevid: 1, title: "Sans genre")
        work.applyEnrichedGenres([])

        #expect(GenreClaims.needsAsking(enrichedAt: work.genresEnrichedAt, revision: work.genresRevision) == false)
    }

    /// `applyEnrichedGenres` is what closes the loop: whatever it stamps must satisfy the rule,
    /// or the two would drift apart on the next revision bump and the book screen would re-ask
    /// every work on every visit.
    @Test("What the enrichment stamps always settles the question")
    func stampingSettlesTheQuestion() {
        let work: Work = .init(uri: "wd:Q42", lastrevid: 1, title: "Un roman")
        #expect(GenreClaims.needsAsking(enrichedAt: work.genresEnrichedAt, revision: work.genresRevision))

        work.applyEnrichedGenres(["Science-fiction"])

        #expect(GenreClaims.needsAsking(enrichedAt: work.genresEnrichedAt, revision: work.genresRevision) == false)
    }
}
