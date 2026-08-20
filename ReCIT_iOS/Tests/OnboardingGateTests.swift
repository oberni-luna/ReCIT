//
//  OnboardingGateTests.swift
//  ReCIT_iOSTests
//
//  Onboarding's whole ruleset, which is why it is a type of its own. Pure and network-free, like
//  the auto-sort suites and the scanner's state machine.
//
//  The case worth the suite is the reinstalling user: on a slow connection their inventory is
//  briefly empty, and an accueil raised over it would offer to scan three hundred books they
//  already own — then remember the answer for good. That failure is invisible in the simulator,
//  where the sync lands before the eye can follow, so it is asserted here rather than looked for
//  on device.
//
//  The bilan's own case worth the suite is the user who created an étagère by hand: the offer
//  stops for them too, because "has arranged their books" is derived from owning one rather than
//  persisted. That is an accepted consequence and not a bug, which is exactly why it is written
//  down as an expectation instead of being rediscovered as one.
//
//  See PRD 0007.
//

import Testing
@testable import ReCIT_iOS

@Suite("OnboardingGate")
struct OnboardingGateTests {

    // MARK: - Waiting for the sync

    @Test("An inventory that has never synced shows nothing, whatever the count says")
    func neverSyncedShowsNothing() {
        // The reinstalling user, mid-sync: no books have arrived yet.
        #expect(
            OnboardingGate.presentsWelcome(
                inventoryHasSynced: false,
                ownedBookCount: 0,
                welcomeAnswered: false
            ) == false
        )

        // And the same user a moment later, with some of them in.
        #expect(
            OnboardingGate.presentsWelcome(
                inventoryHasSynced: false,
                ownedBookCount: 312,
                welcomeAnswered: false
            ) == false
        )
    }

    // MARK: - The accueil's own case

    @Test("A synced, empty, unanswered inventory earns the accueil")
    func syncedAndEmptyAndUnansweredShowsTheWelcome() {
        #expect(
            OnboardingGate.presentsWelcome(
                inventoryHasSynced: true,
                ownedBookCount: 0,
                welcomeAnswered: false
            )
        )
    }

    @Test("Once answered, the accueil does not come back")
    func answeringSuppressesTheWelcome() {
        #expect(
            OnboardingGate.presentsWelcome(
                inventoryHasSynced: true,
                ownedBookCount: 0,
                welcomeAnswered: true
            ) == false
        )
    }

    // MARK: - A user who already owns books

    @Test("A user with books is never offered the accueil, answered or not")
    func ownedBooksSuppressTheWelcome() {
        #expect(
            OnboardingGate.presentsWelcome(
                inventoryHasSynced: true,
                ownedBookCount: 1,
                welcomeAnswered: false
            ) == false
        )

        #expect(
            OnboardingGate.presentsWelcome(
                inventoryHasSynced: true,
                ownedBookCount: 312,
                welcomeAnswered: false
            ) == false
        )
    }

    /// Suppressing the accueil must not depend on the flag: a user who joins with a full
    /// inventory gets no accueil at all, and so never answers one.
    @Test("Books alone suppress it, with no answer needed")
    func booksSuppressItWithoutAnAnswer() {
        let unanswered: Bool = OnboardingGate.presentsWelcome(
            inventoryHasSynced: true,
            ownedBookCount: 42,
            welcomeAnswered: false
        )
        let answered: Bool = OnboardingGate.presentsWelcome(
            inventoryHasSynced: true,
            ownedBookCount: 42,
            welcomeAnswered: true
        )

        #expect(unanswered == false)
        #expect(answered == false)
    }

    // MARK: - The bilan at the end of a session

    @Test("A session that added nothing is not worth reporting")
    func zeroAddSessionShowsNoTally() {
        #expect(
            OnboardingGate.presentsScanTally(
                sessionAddedBookCount: 0,
                ownedShelfCount: 0
            ) == false
        )

        // Not even for a user with no étagère at all: congratulating them on nothing is worse
        // than saying nothing.
        #expect(
            OnboardingGate.presentsScanTally(
                sessionAddedBookCount: 0,
                ownedShelfCount: 3
            ) == false
        )
    }

    @Test("Books added to an inventory with no étagère earn the bilan")
    func booksWithNoShelfShowTheTally() {
        #expect(
            OnboardingGate.presentsScanTally(
                sessionAddedBookCount: 1,
                ownedShelfCount: 0
            )
        )

        #expect(
            OnboardingGate.presentsScanTally(
                sessionAddedBookCount: 24,
                ownedShelfCount: 0
            )
        )
    }

    @Test("A user who already has an étagère is not pitched the arrangement again")
    func anExistingShelfSuppressesTheTally() {
        #expect(
            OnboardingGate.presentsScanTally(
                sessionAddedBookCount: 24,
                ownedShelfCount: 1
            ) == false
        )

        #expect(
            OnboardingGate.presentsScanTally(
                sessionAddedBookCount: 24,
                ownedShelfCount: 12
            ) == false
        )
    }

    /// The accepted consequence of deriving "has arranged their books" from the store rather
    /// than persisting a flag: an étagère made by hand reads exactly like one the arrangement
    /// made, and stops the offer just as well. Nothing distinguishes the two inputs here, which
    /// is the point — a user who created one has shown they know what an étagère is.
    @Test("An étagère created by hand stops the bilan just as an arranged one does")
    func aHandMadeShelfSuppressesTheTallyToo() {
        let beforeCreatingOne: Bool = OnboardingGate.presentsScanTally(
            sessionAddedBookCount: 24,
            ownedShelfCount: 0
        )
        let afterCreatingOne: Bool = OnboardingGate.presentsScanTally(
            sessionAddedBookCount: 24,
            ownedShelfCount: 1
        )

        #expect(beforeCreatingOne)
        #expect(afterCreatingOne == false)
    }

    /// The bilan waits on no sync, unlike the accueil: both of its inputs are facts about a
    /// session that has just run in front of the user, so there is no ambiguity for a sync clause
    /// to remove — and a first-launch user who scans a shelf has, by definition, not synced.
    @Test("The bilan does not wait on a sync the way the accueil does")
    func theTallyIsIndependentOfTheWelcomesConditions() {
        // The user who took the accueil up on its offer: answered it, still owns nothing that
        // came from a server, and has just filed twenty-four books.
        #expect(
            OnboardingGate.presentsWelcome(
                inventoryHasSynced: false,
                ownedBookCount: 24,
                welcomeAnswered: true
            ) == false
        )
        #expect(
            OnboardingGate.presentsScanTally(
                sessionAddedBookCount: 24,
                ownedShelfCount: 0
            )
        )
    }
}
