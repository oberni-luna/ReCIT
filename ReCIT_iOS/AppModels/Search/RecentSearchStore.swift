//
//  RecentSearchStore.swift
//  ReCIT_iOS
//
//  What this account has actually looked for, in the order it looked. `OnboardingStore`'s shape
//  — an observed value mirrored into an injectable `UserDefaults` — made per user.
//
//  **Per user rather than per app**, for the same reason the accueil's answer is: what I search
//  for is a property of my account, not of the phone I hold. Two people sharing a device keep
//  two histories, and signing out erases neither — the history belongs to the account that
//  wrote it, and coming back to it is not a fresh start.
//
//  **On the device and nowhere else.** Nothing here is sent to inventaire.io: a list of the
//  things someone looked for is not part of the inventory they publish.
//
//  Two rules the callers do not get to re-invent:
//
//  - **Only a sent search is remembered.** `record` is called on submit — the keyboard's
//    « rechercher » key, a tap on a suggestion, a tap on a recent — never on a keystroke. A
//    query typed and abandoned leaves nothing, which is the whole reason the list reads as
//    things actually looked for rather than as a transcript of the keyboard.
//  - **Nothing is capped here.** Everything sent is kept; the three rows the screen draws are a
//    display fact, which is what `recentSearches(userId:)` answers and `searches(userId:)` does
//    not. Per-entry deletion is not in this PRD — « Effacer » wipes the lot.
//
//  Two spellings of the same search are one entry: matching folds case and diacritics, so
//  « Monte Cristo » typed after « monte cristo » moves the entry to the front rather than
//  growing a twin, and the front of the list carries the spelling last used.
//
//  See PRD 0012 and issue 0072.
//

import Foundation
import Observation

@MainActor
@Observable
final class RecentSearchStore {

    /// How many of an account's searches the search surface draws. A display cap and nothing
    /// more: the store keeps every one of them.
    static let displayedCount: Int = 3

    /// Each account's searches, most recent first, keyed by `User._id`. Mirrored to
    /// `UserDefaults` and kept observed, so a search sent from the field appears in the recents
    /// without the screen being opened again.
    private var searchesByUserId: [String: [String]]

    private let defaults: UserDefaults
    private static let defaultsKey: String = "RecentSearchStore.searchesByUserId"

    /// - Parameter defaults: where the history is mirrored. Injected so a test — or a second
    ///   store built for a fixture — never writes into the domain the running app reads.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored: [String: Any] = defaults.dictionary(forKey: Self.defaultsKey) ?? [:]
        self.searchesByUserId = stored.compactMapValues { $0 as? [String] }
    }

    // MARK: - Queries

    /// Everything this account has sent, most recent first. Uncapped — the cap belongs to the
    /// screen, and « Tout voir » will read this one (issue 0075).
    func searches(userId: String) -> [String] {
        searchesByUserId[userId] ?? []
    }

    /// The slice the search surface shows at the focus of the field: the last few searches, in
    /// the order they were last sent.
    func recentSearches(userId: String) -> [String] {
        Array(searches(userId: userId).prefix(Self.displayedCount))
    }

    // MARK: - Mutations

    /// Remembers a search that was actually sent, at the front of this account's history.
    ///
    /// Normalises first — trimmed, its inner whitespace collapsed — so « monte   cristo » and
    /// « monte cristo » are not two rows saying the same thing. A query that normalises to
    /// nothing was never a search and is not recorded.
    ///
    /// An entry already there moves to the front rather than being appended a second time, and
    /// it moves carrying the spelling just typed: the history shows what the user last wrote,
    /// not what they wrote first.
    func record(query: String, userId: String) {
        let normalised: String = Self.normalise(query)
        guard !normalised.isEmpty else { return }

        let key: String = Self.foldedKey(normalised)
        var history: [String] = searches(userId: userId)
        history.removeAll { Self.foldedKey($0) == key }
        history.insert(normalised, at: 0)
        searchesByUserId[userId] = history
        persist()
    }

    /// Wipes one account's history — what « Effacer » does. Per user on purpose: a shared phone
    /// must not hand the other account's searches away with mine.
    func clear(userId: String) {
        guard searchesByUserId[userId] != nil else { return }
        searchesByUserId[userId] = nil
        persist()
    }

    // MARK: - Private

    /// The query as it will be stored and drawn: no leading or trailing space, and one space
    /// between words whatever was typed between them.
    private static func normalise(_ query: String) -> String {
        query.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// What decides whether two searches are the same one. Case and accents folded, because
    /// « Monte Cristo », « monte cristo » and « monté cristo » are one search asked three ways —
    /// and because that is already how this app matches what a user types.
    private static func foldedKey(_ query: String) -> String {
        query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func persist() {
        defaults.set(searchesByUserId, forKey: Self.defaultsKey)
    }
}
