//
//  WorkCandidateTests.swift
//  ReCIT_iOSTests
//
//  The line a work is recognised by in the search of « Nouveau livre » — « Kim Stanley Robinson
//  · 2020 » — asserted on the pure type that composes it. Network-free.
//
//  See PRD 0021.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("WorkCandidate")
struct WorkCandidateTests {

    private func result(
        uri: String,
        title: String,
        description: String? = nil
    ) -> SearchResult {
        .init(id: uri, uri: uri, title: title, description: description, score: 1, type: .works)
    }

    private func entity(_ uri: String, label: String, claims: [String: [ClaimValue]]? = nil) -> WorkSummaryDTO {
        .init(uri: uri, labels: ["fr": label], claims: claims)
    }

    // MARK: - The year

    @Test("The year is read off a full date, a month and a bare year")
    func yearOfADate() {
        #expect(WorkCandidate.year(of: "2020-10-06") == "2020")
        #expect(WorkCandidate.year(of: "2020-10") == "2020")
        #expect(WorkCandidate.year(of: "2020") == "2020")
    }

    @Test("A date before the common era, or no date, gives no year")
    func noYear() {
        #expect(WorkCandidate.year(of: "-0500") == nil)
        #expect(WorkCandidate.year(of: nil) == nil)
        #expect(WorkCandidate.year(of: "19") == nil)
    }

    // MARK: - The byline

    @Test("Authors and year are joined by a middle dot, authors by a comma")
    func bylineJoinsBoth() {
        #expect(WorkCandidate.byline(authors: ["Ursula K. Le Guin"], year: "1969") == "Ursula K. Le Guin · 1969")
        #expect(WorkCandidate.byline(authors: ["Michel Pinçon", "Monique Pinçon-Charlot"], year: nil)
            == "Michel Pinçon, Monique Pinçon-Charlot")
        #expect(WorkCandidate.byline(authors: [], year: "2019") == "2019")
        #expect(WorkCandidate.byline(authors: [], year: nil) == nil)
    }

    // MARK: - From a search and a by-uris envelope

    @Test("A work is completed by its authors' names and its year, read from the same envelope")
    func candidatesReadAuthorsFromRelatives() throws {
        let entities: [String: WorkSummaryDTO] = [
            "wd:Q102036201": entity(
                "wd:Q102036201",
                label: "Le Ministère du futur",
                claims: ["wdt:P50": [.string("wd:Q130779")], "wdt:P577": [.string("2020-10-06")]]
            ),
            "wd:Q130779": entity("wd:Q130779", label: "Kim Stanley Robinson")
        ]

        let candidates: [WorkCandidate] = WorkCandidate.candidates(
            from: [result(uri: "wd:Q102036201", title: "Le Ministère du futur", description: "roman")],
            entities: entities
        )

        let candidate: WorkCandidate = try #require(candidates.first)
        #expect(candidate.authors == ["Kim Stanley Robinson"])
        #expect(candidate.year == "2020")
        #expect(candidate.detail == "Kim Stanley Robinson · 2020")
    }

    /// The by-uris call can fail, or know nothing about a work: the search's own description
    /// often names the author and the year anyway.
    @Test("A work the envelope says nothing about keeps the search's description")
    func candidatesFallBackOnTheDescription() throws {
        let candidates: [WorkCandidate] = WorkCandidate.candidates(
            from: [result(uri: "inv:abc", title: "Ratna krila", description: "roman d’Erin Morgenstern (2011)")],
            entities: [:]
        )

        #expect(try #require(candidates.first).detail == "roman d’Erin Morgenstern (2011)")
    }

    @Test("The search's order is kept")
    func candidatesKeepTheSearchOrder() {
        let candidates: [WorkCandidate] = WorkCandidate.candidates(
            from: [result(uri: "wd:2", title: "B"), result(uri: "wd:1", title: "A")],
            entities: [:]
        )

        #expect(candidates.map(\.uri) == ["wd:2", "wd:1"])
    }
}
