//
//  OnboardingStoreTests.swift
//  ReCIT_iOSTests
//
//  The one fact onboarding persists, checked through the store's public surface with a
//  `UserDefaults` of its own per test — never `.standard`, which the running app writes to and
//  which would leak one case's answer into the next.
//
//  Two of these cases are the reason the store is per user rather than per app: a phone shared by
//  two accounts owes the second one its own first launch, and an answer has to survive the process
//  that gave it. Both are launch-shaped failures — the kind nobody reproduces by hand twice.
//
//  See PRD 0007.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("OnboardingStore")
@MainActor
struct OnboardingStoreTests {

    private let alice: String = "usr:alice"
    private let bob: String = "usr:bob"

    /// A defaults domain nobody else writes to, torn down with the test.
    private func makeDefaults() throws -> UserDefaults {
        let suiteName: String = "OnboardingStoreTests.\(UUID().uuidString)"
        let defaults: UserDefaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        return try #require(UserDefaults(suiteName: suiteName))
    }

    @Test("A user who has never seen the accueil has not answered it")
    func unansweredByDefault() throws {
        let store: OnboardingStore = .init(defaults: try makeDefaults())

        #expect(store.hasAnsweredWelcome(userId: alice) == false)
    }

    @Test("Answering is remembered")
    func answeringIsRemembered() throws {
        let store: OnboardingStore = .init(defaults: try makeDefaults())

        store.markWelcomeAnswered(userId: alice)

        #expect(store.hasAnsweredWelcome(userId: alice))
    }

    @Test("A second account on the same phone gets its own accueil")
    func oneUsersAnswerLeavesTheOtherAlone() throws {
        let store: OnboardingStore = .init(defaults: try makeDefaults())

        store.markWelcomeAnswered(userId: alice)

        #expect(store.hasAnsweredWelcome(userId: bob) == false)
    }

    @Test("An answer survives the launch that gave it")
    func answerSurvivesANewStore() throws {
        let defaults: UserDefaults = try makeDefaults()
        let firstLaunch: OnboardingStore = .init(defaults: defaults)

        firstLaunch.markWelcomeAnswered(userId: alice)

        let nextLaunch: OnboardingStore = .init(defaults: defaults)
        #expect(nextLaunch.hasAnsweredWelcome(userId: alice))
        // And still only for the account that answered.
        #expect(nextLaunch.hasAnsweredWelcome(userId: bob) == false)
    }

    @Test("Both accounts' answers are kept, not the last one written")
    func twoAccountsCanBothHaveAnswered() throws {
        let defaults: UserDefaults = try makeDefaults()
        let store: OnboardingStore = .init(defaults: defaults)

        store.markWelcomeAnswered(userId: alice)
        store.markWelcomeAnswered(userId: bob)

        let nextLaunch: OnboardingStore = .init(defaults: defaults)
        #expect(nextLaunch.hasAnsweredWelcome(userId: alice))
        #expect(nextLaunch.hasAnsweredWelcome(userId: bob))
    }

    @Test("Resetting one account hands back its accueil and only its own")
    func resettingIsPerAccount() throws {
        let defaults: UserDefaults = try makeDefaults()
        let store: OnboardingStore = .init(defaults: defaults)
        store.markWelcomeAnswered(userId: alice)
        store.markWelcomeAnswered(userId: bob)

        store.resetWelcome(userId: alice)

        #expect(store.hasAnsweredWelcome(userId: alice) == false)
        #expect(store.hasAnsweredWelcome(userId: bob))
        // Written through, not just forgotten in memory.
        let nextLaunch: OnboardingStore = .init(defaults: defaults)
        #expect(nextLaunch.hasAnsweredWelcome(userId: alice) == false)
        #expect(nextLaunch.hasAnsweredWelcome(userId: bob))
    }
}
