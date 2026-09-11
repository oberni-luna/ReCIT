//
//  RemoteSearchStateTests.swift
//  ReCIT_iOSTests
//
//  The three things the search must never confuse — "it is loading", "there is nothing", "it
//  did not work" — driven by values rather than by a screen.
//
//  The suite is written against what a user would notice: which of the three signs the screen
//  shows, and whether results are drawn under it. It asserts the exclusivity explicitly, since
//  that is the whole reason the type exists — two signs at once is the bug this replaces.
//
//  See issue 0076 and PRD 0012.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("RemoteSearchState")
struct RemoteSearchStateTests {

    private func result(_ title: String) -> SearchResult {
        SearchResult(
            id: title,
            uri: "wd:\(title)",
            title: title,
            score: 1,
            type: .works
        )
    }

    // MARK: - The three signs

    @Test("A call that has not been sent says nothing at all")
    func idleSaysNothing() {
        #expect(RemoteSearchState.idle.sign == nil)
        #expect(RemoteSearchState.idle.results.isEmpty)
    }

    @Test("A call in flight shows the loading sign")
    func loadingShowsItsSign() {
        #expect(RemoteSearchState.loading.sign == .loading)
    }

    @Test("An empty answer is a result of its own: no result, not nothing")
    func emptyAnswerShowsNoResult() {
        #expect(RemoteSearchState.loaded([]).sign == .noResult)
    }

    @Test("A failed call says it failed")
    func failureShowsItsSign() {
        #expect(RemoteSearchState.failed.sign == .failure)
    }

    @Test("An answer with results shows no sign — the results speak")
    func resultsShowNoSign() {
        #expect(RemoteSearchState.loaded([result("Monte-Cristo")]).sign == nil)
    }

    // MARK: - What is drawn under the sign

    @Test("Only a loaded answer carries results")
    func onlyALoadedAnswerCarriesResults() {
        #expect(RemoteSearchState.loaded([result("Monte-Cristo")]).results.count == 1)
        #expect(RemoteSearchState.loading.results.isEmpty)
        #expect(RemoteSearchState.failed.results.isEmpty)
        #expect(RemoteSearchState.idle.results.isEmpty)
    }

    @Test("A failure never leaves the previous query's results on screen")
    func aFailureDropsWhatWasThere() {
        var state: RemoteSearchState = .loaded([result("Monte-Cristo")])
        state = .failed

        #expect(state.results.isEmpty)
        #expect(state.sign == .failure)
    }

    // MARK: - The distinction itself

    @Test("Loading, nothing found and a failure are three different states")
    func theThreeStatesAreDistinct() {
        let signs: [RemoteSearchState.Sign?] = [
            RemoteSearchState.loading.sign,
            RemoteSearchState.loaded([]).sign,
            RemoteSearchState.failed.sign
        ]

        #expect(signs == [.loading, .noResult, .failure])
        #expect(Set(signs.compactMap { $0.map(String.init(describing:)) }).count == 3)
    }

    @Test("Nothing found is not the same value as nothing asked")
    func anEmptyAnswerIsNotAnAbsentOne() {
        #expect(RemoteSearchState.loaded([]) != RemoteSearchState.idle)
    }
}
