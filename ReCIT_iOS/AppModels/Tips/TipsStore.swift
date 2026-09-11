//
//  TipsStore.swift
//  ReCIT_iOS
//
//  The one thing the astuces have to remember: which gestures this account has already
//  done. `OnboardingStore`'s shape — an observed value mirrored into an injectable
//  `UserDefaults` — made per user.
//
//  **Per user rather than per app**, for the same reason onboarding's answer is: a first
//  time is a property of an account and not of a phone. Two people sharing a device each
//  get their own astuces, and resetting one account for QA leaves the other alone. It is
//  also why signing out clears nothing — coming back to your own library is not a first
//  time.
//
//  **This, and not TipKit's datastore, is what "has learned" means.** TipKit keeps its own
//  per-application record of what it has displayed; it has no idea who is signed in, so
//  left to itself it would teach the first account and silently rob the second. The `Tip`
//  structs' boolean parameters are derived from what is stored here, through `SortTipGate`.
//
//  See PRD 0013 and issue 0077.
//

import Foundation
import Observation

@MainActor
@Observable
final class TipsStore {

    /// What each account has been taught, keyed by `User._id`. Mirrored to `UserDefaults`
    /// and kept observed, so the surface stops offering an astuce the instant the gesture
    /// it teaches is made — without waiting for the screen to be opened again.
    private var learnedTipsByUserId: [String: Set<SortTip>]

    private let defaults: UserDefaults
    private static let defaultsKey: String = "TipsStore.learnedTipsByUserId"

    /// - Parameter defaults: where the record is mirrored. Injected so a test — or a second
    ///   store built for a fixture — never writes into the domain the running app reads.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored: [String: Any] = defaults.dictionary(forKey: Self.defaultsKey) ?? [:]
        self.learnedTipsByUserId = stored.reduce(into: [:]) { result, entry in
            guard let rawValues = entry.value as? [String] else { return }
            result[entry.key] = Set(rawValues.compactMap(SortTip.init(rawValue:)))
        }
    }

    // MARK: - Queries

    /// Everything this account has already been taught. Handed to `SortTipGate` whole rather
    /// than asked astuce by astuce: the gate answers *which one is due*, so it needs the set.
    func learnedTips(userId: String) -> Set<SortTip> {
        learnedTipsByUserId[userId] ?? []
    }

    /// Whether this account has already done the gesture this astuce teaches.
    func hasLearned(_ tip: SortTip, userId: String) -> Bool {
        learnedTips(userId: userId).contains(tip)
    }

    // MARK: - Mutations

    /// Records that the gesture has been made. Persisted, so the next launch does not teach
    /// it again.
    ///
    /// Only ever called for a gesture that actually happened — a refused drop teaches
    /// nothing, and closing a card with its cross teaches nothing either. That distinction
    /// is the whole reason this is a separate fact from "the card has been displayed", which
    /// is all TipKit's own datastore knows.
    func markLearned(_ tip: SortTip, userId: String) {
        guard learnedTips(userId: userId).contains(tip) == false else { return }
        learnedTipsByUserId[userId, default: []].insert(tip)
        persist()
    }

    /// Hands one account all of its astuces back. Per user on purpose: resetting for QA must
    /// not re-teach the other account on the same phone.
    ///
    /// It does not touch TipKit's own datastore — that is per application, and clearing it is
    /// the caller's business (the profile's Debug row, issue 0078).
    func resetTips(userId: String) {
        guard learnedTipsByUserId[userId] != nil else { return }
        learnedTipsByUserId[userId] = nil
        persist()
    }

    // MARK: - Private

    private func persist() {
        let stored: [String: [String]] = learnedTipsByUserId.mapValues { tips in
            tips.map(\.rawValue).sorted()
        }
        defaults.set(stored, forKey: Self.defaultsKey)
    }
}
