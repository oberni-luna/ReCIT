//
//  ResolveRequestBuilder.swift
//  ReCIT_iOS
//
//  Turns what the reader typed into the request that creates a book. Pure — no network, no
//  SwiftData, no SwiftUI — so the rules that matter can be asserted against the body that goes
//  on the wire instead of against a screenshot.
//
//  The rules, all of them one sentence long:
//
//  - The ISBN travels normalized, as `wdt:P212`. It is the only thing the app is certain of.
//  - `wdt:P1476` is the title of *this edition*, which is not the title of the work: a
//    translation, a reissue and a boxed set share a work and disagree about their covers.
//  - An author already on inventaire is named by uri; one being created is described by label.
//    Same for the work. That single distinction is what keeps the base free of twins.
//
//  See PRD 0015.
//

import Foundation

enum ResolveRequestBuilder {

    /// Properties of the inventaire data model, spelled out once so no call site has to know
    /// what `P1476` means.
    private enum Property {
        static let isbn13: String = "wdt:P212"
        static let editionTitle: String = "wdt:P1476"
        static let language: String = "wdt:P407"
    }

    /// The language the labels are written in when the ISBN has not answered. The language the
    /// reader is reading the app in is the best guess available then, and a wrong label
    /// language is a nuisance rather than a falsehood.
    static var defaultLabelLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "fr"
    }

    /// The request that creates the book, or — with `create: false` — the one that merely asks
    /// inventaire.io what it already knows about it.
    static func request(
        for draft: NewBookDraft,
        create: Bool,
        language: String = defaultLabelLanguage
    ) -> EntityResolveRequest {
        // What the ISBN says wins over what the phone is set to: the group of an ISBN is handed
        // out by language area, so it knows the book's language and the phone only knows the
        // reader's.
        let labelLanguage: String = draft.language?.code ?? language

        var editionClaims: [String: [String]] = [
            Property.isbn13: [draft.normalizedISBN],
            Property.editionTitle: [draft.trimmedTitle]
        ]

        // Omitted rather than guessed. A wrong language on a public edition is read by everyone
        // afterwards as a fact somebody checked.
        if let languageUri = draft.language?.uri {
            editionClaims[Property.language] = [languageUri]
        }

        let edition: EntityResolveRequest.Seed = .init(claims: editionClaims)

        let work: EntityResolveRequest.Seed = .described(
            label: draft.trimmedTitle,
            language: labelLanguage
        )

        let author: EntityResolveRequest.Seed = .described(
            label: draft.trimmedAuthorName,
            language: labelLanguage
        )

        return .init(
            entries: [.init(edition: edition, works: [work], authors: [author])],
            create: create,
            // Even when nothing is being created: a reconnaissance pass that comes back with a
            // cover has told us something worth keeping.
            enrich: true,
            // Half an entry is worse than none. A work created without its edition leaves an
            // orphan on the website that only a human can clean up.
            strict: true
        )
    }
}
