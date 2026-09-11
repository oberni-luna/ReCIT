//
//  SearchPhaseTests.swift
//  ReCIT_iOSTests
//
//  The threshold, and what the screen shows on either side of it. Pure and network-free, like
//  the batch-scanner suite: the phase is driven by values, not by a keyboard.
//
//  The suite is written against what a user would notice — "two characters show nothing new",
//  "a field full of spaces is an empty field" — rather than against the number three, which is
//  read from `SearchPhase.minimumQueryLength` so that moving the threshold moves the tests with
//  it instead of breaking them.
//
//  See PRD 0012.
//

import Testing
@testable import ReCIT_iOS

@Suite("SearchPhase")
struct SearchPhaseTests {

    private func phase(
        focused: Bool = true,
        _ query: String,
        submitted: String? = nil
    ) -> SearchPhase? {
        SearchPhase.current(isFocused: focused, query: query, submittedQuery: submitted)
    }

    // MARK: - The threshold

    @Test("An empty field shows the recent searches")
    func emptyQueryShowsRecents() {
        #expect(phase("") == .recents)
    }

    @Test("One character is below the threshold: nothing new appears")
    func oneCharacterStaysBelowTheThreshold() {
        #expect(phase("m") == .typing(query: "m"))
    }

    @Test("Two characters are still below the threshold")
    func twoCharactersStayBelowTheThreshold() {
        #expect(phase("mo") == .typing(query: "mo"))
    }

    @Test("Three characters open the local matches and the ways on")
    func threeCharactersReachSuggesting() {
        #expect(phase("mon") == .suggesting(query: "mon"))
    }

    @Test("Past three characters the screen stays in suggesting")
    func moreThanThreeCharactersStaySuggesting() {
        #expect(phase("monte cristo") == .suggesting(query: "monte cristo"))
    }

    @Test("The threshold is the one the type publishes, wherever it is set")
    func thresholdIsTheOneTheTypePublishes() {
        let atThreshold: String = .init(repeating: "a", count: SearchPhase.minimumQueryLength)
        let justBelow: String = .init(atThreshold.dropLast())

        #expect(phase(atThreshold) == .suggesting(query: atThreshold))
        #expect(phase(justBelow) == .typing(query: justBelow))
    }

    // MARK: - Whitespace

    @Test("A field full of spaces is an empty field")
    func whitespaceOnlyQueryIsEmpty() {
        #expect(phase("   ") == .recents)
        #expect(phase("\n\t ") == .recents)
    }

    @Test("Padding does not count towards the threshold, and is trimmed off the query")
    func paddingIsTrimmedBeforeCounting() {
        #expect(phase("  mo  ") == .typing(query: "mo"))
        #expect(phase("  mon  ") == .suggesting(query: "mon"))
    }

    @Test("A whitespace-only query is never treated as a submitted search")
    func whitespaceOnlyQueryNeverReachesResults() {
        #expect(phase("   ", submitted: "   ") == .recents)
    }

    // MARK: - Submitting

    @Test("A submitted query gives the screen to its results")
    func submittingShowsResults() {
        #expect(phase("monte cristo", submitted: "monte cristo") == .results(query: "monte cristo"))
    }

    @Test("Editing the query after a search leaves the results behind")
    func editingAfterSubmitLeavesResults() {
        #expect(phase("monte crist", submitted: "monte cristo") == .suggesting(query: "monte crist"))
    }

    @Test("Deleting back under the threshold after a search leaves the results too")
    func editingUnderTheThresholdAfterSubmitLeavesResults() {
        #expect(phase("mo", submitted: "monte cristo") == .typing(query: "mo"))
        #expect(phase("", submitted: "monte cristo") == .recents)
    }

    @Test("Typing the sent query back reaches its results again rather than a third state")
    func retypingTheSubmittedQueryReturnsToResults() {
        #expect(phase("monte crist", submitted: "monte cristo") == .suggesting(query: "monte crist"))
        #expect(phase("monte cristo", submitted: "monte cristo") == .results(query: "monte cristo"))
    }

    @Test("Padding typed around a sent query is not an edit")
    func paddingDoesNotLeaveTheResults() {
        #expect(phase("  monte cristo ", submitted: "monte cristo") == .results(query: "monte cristo"))
    }

    @Test("A search sent for something else does not claim the query being typed")
    func anUnrelatedSubmissionDoesNotClaimTheQuery() {
        #expect(phase("hugo", submitted: "monte cristo") == .suggesting(query: "hugo"))
    }

    // MARK: - Focus

    @Test("Losing the focus with nothing sent closes the search surface")
    func losingFocusClosesTheSurface() {
        #expect(phase(focused: false, "mon") == nil)
        #expect(phase(focused: false, "") == nil)
    }

    @Test("Results survive the keyboard going away, since submitting is what dismisses it")
    func resultsSurviveLosingFocus() {
        #expect(phase(focused: false, "mon", submitted: "mon") == .results(query: "mon"))
    }

    // MARK: - The query a phase carries

    @Test("Every phase but recents names the query it is about")
    func phasesCarryTheirQuery() {
        #expect(SearchPhase.recents.query == nil)
        #expect(SearchPhase.typing(query: "mo").query == "mo")
        #expect(SearchPhase.suggesting(query: "mon").query == "mon")
        #expect(SearchPhase.results(query: "mon").query == "mon")
    }
}
