//
//  FriendsCarouselStateTests.swift
//  ReCIT_iOSTests
//
//  What « Chez mes amis » draws, from the phase and two counts. Written against what a reader
//  would notice — "typing makes it leave", "no friend is an invitation" — and against
//  `FriendsCarouselState.limit` rather than the number ten.
//
//  See PRD 0020 and issue 0117.
//

import Testing
@testable import ReCIT_iOS

@Suite("FriendsCarouselState")
struct FriendsCarouselStateTests {

    private func state(
        _ phase: SearchPhase = .recents,
        hasFriends: Bool = true,
        books: Int = 4
    ) -> FriendsCarouselState {
        FriendsCarouselState.current(
            phase: phase,
            hasFriends: hasFriends,
            friendsBookCount: books
        )
    }

    // MARK: - Rest only

    @Test("At rest, my friends' books show")
    func restShowsTheBooks() {
        #expect(state() == .recent(shownCount: 4, showsSeeAll: false))
    }

    @Test("From the first character typed, the carousel leaves")
    func typingHidesIt() {
        #expect(state(.typing(query: "o")) == .hidden)
        #expect(state(.suggesting(query: "oli")) == .hidden)
        #expect(state(.results(query: "oli")) == .hidden)
    }

    @Test("Typing hides the invitation too")
    func typingHidesTheInvitation() {
        #expect(state(.typing(query: "o"), hasFriends: false) == .hidden)
    }

    // MARK: - Friends, books

    @Test("No friend is an invitation toward Réseau")
    func noFriendIsAnInvitation() {
        #expect(state(hasFriends: false, books: 0) == .invitation)
    }

    @Test("Friends with no book draw nothing")
    func friendsWithoutBooksAreSilent() {
        #expect(state(books: 0) == .hidden)
    }

    // MARK: - The cap

    @Test("Exactly the limit shows them all, with nothing more to see")
    func atTheLimitThereIsNoSeeAll() {
        let limit: Int = FriendsCarouselState.limit

        #expect(state(books: limit) == .recent(shownCount: limit, showsSeeAll: false))
    }

    @Test("Past the limit, the row is capped and « Tout voir » appears")
    func pastTheLimitOffersSeeAll() {
        let limit: Int = FriendsCarouselState.limit

        #expect(state(books: limit + 1) == .recent(shownCount: limit, showsSeeAll: true))
    }
}
