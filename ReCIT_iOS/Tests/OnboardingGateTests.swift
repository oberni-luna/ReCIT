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
//  on device. See PRD 0007.
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
}
