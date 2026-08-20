//
//  OnboardingStore.swift
//  ReCIT_iOS
//
//  The one thing onboarding has to remember: that the accueil has been answered. `SyncStatusStore`'s
//  shape — an observed set mirrored into an injectable `UserDefaults` — made per user.
//
//  Per user rather than per app, because a first launch is a property of an account and not of a
//  phone. Two people sharing a device each get their own accueil, and resetting one account for QA
//  leaves the other alone. It is also the reason logging out does not clear anything: the answer
//  belongs to the account that gave it, and coming back to it is not a first launch.
//
//  Nothing else about onboarding is persisted. "The user has already arranged their books" is
//  derived from the store — they own an étagère — rather than recorded here, so a shelf created by
//  hand counts too. The decisions themselves live in `OnboardingGate`; this only remembers the one
//  fact none of them could work out from the database.
//
//  See PRD 0007.
//

import Foundation
import Observation

@MainActor
@Observable
final class OnboardingStore {

    /// Users who have answered the accueil. Mirrored to `UserDefaults` and kept as an observed
    /// property so the cover that reads it dismisses itself the moment it is answered.
    private var welcomeAnsweredUserIds: Set<String>

    private let defaults: UserDefaults
    private static let defaultsKey: String = "OnboardingStore.welcomeAnsweredUserIds"

    #if DEBUG
    /// Debug scaffolding: presents the accueil even where the inventory holds books.
    ///
    /// The accueil's condition is three clauses, and only one of them — the answer — is
    /// anything a debug row can reasonably forget. The other two describe an account that
    /// really is new, and reproducing them for real would mean deleting the tester's own
    /// books off inventaire.io. So this stands in for the empty-inventory clause instead,
    /// and the debug section says out loud that it is doing so.
    ///
    /// Persisted, because the interesting moment is a *launch*: an override that forgot
    /// itself on relaunch could only ever show the accueil mid-session, which is the one
    /// thing the two other debug rows already do.
    ///
    /// Cleared by answering, like the answer itself — otherwise the cover would come
    /// straight back and the screen would be a trap.
    var forcesWelcome: Bool {
        didSet { defaults.set(forcesWelcome, forKey: Self.forcesWelcomeKey) }
    }

    private static let forcesWelcomeKey: String = "OnboardingStore.debugForcesWelcome"
    #endif

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored: [String] = defaults.stringArray(forKey: Self.defaultsKey) ?? []
        self.welcomeAnsweredUserIds = Set(stored)
        #if DEBUG
        self.forcesWelcome = defaults.bool(forKey: Self.forcesWelcomeKey)
        #endif
    }

    // MARK: - Queries

    /// Whether this user has answered the accueil, by scanning or by putting it off. Both
    /// answers count, so this is one flag and not two.
    func hasAnsweredWelcome(userId: String) -> Bool {
        welcomeAnsweredUserIds.contains(userId)
    }

    // MARK: - Mutations

    /// Records that the accueil has been answered. Persisted, so the next launch does not ask again.
    func markWelcomeAnswered(userId: String) {
        #if DEBUG
        // A forced accueil that stayed forced would reappear the instant it was answered.
        forcesWelcome = false
        #endif
        guard !welcomeAnsweredUserIds.contains(userId) else { return }
        welcomeAnsweredUserIds.insert(userId)
        persist()
    }

    /// Forgets one user's answer, so their next launch shows the accueil again. Per user on
    /// purpose: resetting for QA must not hand a first launch back to the other account on the
    /// same phone.
    func resetWelcome(userId: String) {
        guard welcomeAnsweredUserIds.contains(userId) else { return }
        welcomeAnsweredUserIds.remove(userId)
        persist()
    }

    // MARK: - Private

    private func persist() {
        defaults.set(welcomeAnsweredUserIds.sorted(), forKey: Self.defaultsKey)
    }
}
