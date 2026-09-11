//
//  SearchSuggestion.swift
//  ReCIT_iOS
//
//  The three ways out of my own shelves and on to inventaire.io: the books whose title holds
//  what I typed, the people whose name does, and the raw query that asks for both at once.
//
//  The point of this type is that **a suggestion carries the call it will make**. A row that
//  says « Livres contenant *mont* » and a request that asks for `types=humans|works` are the
//  same bug twice — one wrong label, one wrong result list — and the only way to be sure they
//  agree is to read them from one place. So the glyph, the sentence and the entity types of the
//  request all hang off `Kind`, and the view that draws a row and the model that builds the
//  endpoint are handed the same value.
//
//  The keyboard's « rechercher » key sends the third suggestion (`.everything`) rather than a
//  bare string, for the same reason: there is one shape of submission in this screen, not two.
//
//  The threshold is `SearchPhase.minimumQueryLength`, read and never re-written: below it there
//  is no suggestion to make, and `suggestions(for:)` and `everything(for:)` both come back
//  empty rather than offering a call the network would refuse.
//
//  Pure — Foundation only, no SwiftUI, no SwiftData — so the order of the three and the types
//  they carry are driven by values in a test.
//
//  See PRD 0012.
//

import Foundation

struct SearchSuggestion: Identifiable, Equatable, Sendable {
    /// What a suggestion asks inventaire.io for. Each case owns its glyph and its entity types,
    /// which is what keeps the row and the request from drifting apart.
    enum Kind: String, CaseIterable, Sendable {
        /// Works only: the books whose title holds the query.
        case works
        /// Humans only: the people whose name holds it.
        case humans
        /// Both at once — the query as typed, for when I do not know which of the two I want.
        case everything

        /// The `types=` of the search request, in the order the endpoint expects them.
        var entityTypes: [SearchResultType] {
            switch self {
            case .works: [.works]
            case .humans: [.humans]
            case .everything: [.humans, .works]
            }
        }

        /// The SF Symbol the row draws: a book, a signature for the people who write them, a
        /// magnifier for the query that asks for everything.
        var glyph: String {
            switch self {
            case .works: "book.closed"
            case .humans: "signature"
            case .everything: "magnifyingglass"
            }
        }
    }

    let kind: Kind
    /// The query as it will be sent — trimmed once, here, so no caller has to remember to.
    let query: String

    var id: String { "\(kind.rawValue):\(query)" }

    /// The entity types this suggestion's request asks for.
    var entityTypes: [SearchResultType] { kind.entityTypes }

    /// The SF Symbol its row draws.
    var glyph: String { kind.glyph }

    init(
        kind: Kind,
        query: String
    ) {
        self.kind = kind
        self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The three suggestions, always in this order — books, people, everything — so the row a
    /// user reaches for is in the same place from one search to the next. Empty below the
    /// threshold.
    static func suggestions(for query: String) -> [SearchSuggestion] {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= SearchPhase.minimumQueryLength else { return [] }

        return Kind.allCases.map { .init(kind: $0, query: trimmed) }
    }

    /// What the keyboard's « rechercher » key sends: the query as typed, against both types.
    /// `nil` below the threshold — pressing the key on two characters asks for nothing.
    static func everything(for query: String) -> SearchSuggestion? {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= SearchPhase.minimumQueryLength else { return nil }

        return .init(kind: .everything, query: trimmed)
    }

    /// The row's label, with the query in bold inside it: what will be searched, shown rather
    /// than described. The raw suggestion is nothing but the query, so it is bold end to end.
    var label: AttributedString {
        Self.emphasising(query, in: sentence)
    }

    /// What VoiceOver reads. The two named suggestions already say what they do; the raw one
    /// reads as a bare query on screen, and three rows carrying the same words are only
    /// distinguishable if this one names its destination out loud.
    var spokenLabel: String {
        switch kind {
        case .works, .humans:
            sentence
        case .everything:
            String(localized: "inventory.search.suggestion.everything \(query)")
        }
    }

    /// The localised sentence the row draws, before the query inside it is emphasised.
    private var sentence: String {
        switch kind {
        case .works:
            String(localized: "inventory.search.suggestion.works \(query)")
        case .humans:
            String(localized: "inventory.search.suggestion.humans \(query)")
        case .everything:
            query
        }
    }

    /// The sentence with `query` marked as strongly emphasised. Split out from `label` so the
    /// emphasis can be tested without a bundle to localise against — the catalogue lives in the
    /// app, and a unit test has no business depending on which words a translator chose.
    ///
    /// Searched backwards and loosely: the query sits at the end of both translations, and a
    /// user who typed « emile » must still see the word the sentence holds highlighted.
    static func emphasising(_ query: String, in sentence: String) -> AttributedString {
        var label: AttributedString = .init(sentence)
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive, .backwards]

        if let range = label.range(of: query, options: options) {
            label[range].inlinePresentationIntent = .stronglyEmphasized
        }

        return label
    }
}
