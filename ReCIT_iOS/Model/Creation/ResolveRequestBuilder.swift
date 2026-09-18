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
    }

    /// The language the labels are written in. Overridden by what the ISBN says about the book
    /// once that is known (issue 0092); until then, the language the reader is reading the app
    /// in is the best guess available, and a wrong label language is a nuisance rather than a
    /// falsehood.
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
        let edition: EntityResolveRequest.Seed = .init(
            claims: [
                Property.isbn13: [draft.normalizedISBN],
                Property.editionTitle: [draft.trimmedTitle]
            ]
        )

        let work: EntityResolveRequest.Seed = .described(
            label: draft.trimmedTitle,
            language: language
        )

        let author: EntityResolveRequest.Seed = .described(
            label: draft.trimmedAuthorName,
            language: language
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
