//
//  SearchPhase.swift
//  ReCIT_iOS
//
//  What the inventory's search surface shows right now, computed from the three things the
//  screen knows: whether the field is being edited, what has been typed, and whether a search
//  has been sent for exactly that text. Pure — no SwiftUI, no SwiftData — so the rule can be
//  driven by values in a test instead of by a keyboard.
//
//  **It owns the three-character threshold**, which is written nowhere else. Before this type
//  the number lived in `SearchView.isRemoteSectionVisible` — the search tab's own screen, gone
//  at issue 0074 — far from the view that had to stay silent below it, which is how the screen
//  came to look broken between one and two characters:
//  the network waited for three, the screen did not, and an empty section sat under the field.
//  One type answers both questions now, so they cannot disagree.
//
//  Two of the four cases are not rendered yet. `recents` waits for the recent-search store and
//  `results` for the remote call (issues 0072 and 0071); under three characters the screen
//  deliberately shows nothing new. They are cases here from the start because the threshold is
//  only half the rule — the other half is what the screen shows on either side of it, and a
//  phase bolted on later would have to re-derive it.
//
//  See PRD 0012.
//

import Foundation

enum SearchPhase: Equatable, Sendable {
    /// How many characters the query needs before the screen offers anything beyond the recent
    /// searches. The app's one copy of that number.
    static let minimumQueryLength: Int = 3

    /// The field is open and empty: the recent searches have the screen.
    case recents
    /// One or two characters — below the threshold. The recents stay; nothing new appears.
    case typing(query: String)
    /// Three characters or more: the local matches, and later the ways on to inventaire.io.
    case suggesting(query: String)
    /// A search has been sent for this exact query: its full results have the screen.
    case results(query: String)

    /// The phase the screen is in, or `nil` when there is no search surface at all — the field
    /// is not being edited and nothing has been sent, so the inventory itself is showing.
    ///
    /// A submitted query outranks the focus: sending a search dismisses the keyboard, and the
    /// results have to survive that. Editing the query afterwards no longer matches what was
    /// sent, which is what carries the screen back out of `results` on its own.
    static func current(
        isFocused: Bool,
        query: String,
        submittedQuery: String?
    ) -> SearchPhase? {
        let trimmed: String = Self.normalise(query)

        if let submittedQuery, !trimmed.isEmpty, Self.normalise(submittedQuery) == trimmed {
            return .results(query: trimmed)
        }

        guard isFocused else { return nil }

        if trimmed.count >= Self.minimumQueryLength {
            return .suggesting(query: trimmed)
        } else if trimmed.isEmpty {
            return .recents
        } else {
            return .typing(query: trimmed)
        }
    }

    /// The trimmed query this phase carries, if it carries one. `recents` carries none — there
    /// is nothing to search for yet.
    var query: String? {
        switch self {
        case .recents:
            nil
        case .typing(let query), .suggesting(let query), .results(let query):
            query
        }
    }

    /// A query made only of whitespace is no query at all, which is why trimming happens once,
    /// here, rather than at each call site.
    private static func normalise(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
