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
//  - A work that exists is named, never left out, and sends no author: it has its own.
//
//  See PRD 0015 and PRD 0026.
//

import Foundation

enum ResolveRequestBuilder {

    /// Properties of the inventaire data model, spelled out once so no call site has to know
    /// what `P1476` means.
    private enum Property {
        static let isbn13: String = "wdt:P212"
        static let editionTitle: String = "wdt:P1476"
        static let language: String = "wdt:P407"
        static let editionOf: String = "wdt:P629"
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

        // A work the reader picked or recognised is pointed at, not described a second time: the
        // edition claims to be an edition *of it*, and the work seed names it by uri. Describing
        // it again would offer the server a work to create next to the one it just found.
        if let workUri = draft.workUri {
            editionClaims[Property.editionOf] = [workUri]
        }

        // An uploaded cover is offered, never required: `enrich` is what covers the books
        // nobody photographed, and a failed upload must not cost a contribution.
        let edition: EntityResolveRequest.Seed = .init(
            claims: editionClaims,
            image: draft.coverImageUrl
        )

        // A work that exists is named, never left out. An entry with no work seed is not an
        // entry without a work: the server builds one from the edition's title
        // (`sanitize_entry.ts`), which can then match another work or be created beside the one
        // claimed above. A named seed is taken as resolved and reused as it is.
        let works: [EntityResolveRequest.Seed] = if let workUri = draft.workUri {
            [.named(workUri)]
        } else {
            [.described(label: draft.trimmedWorkTitle, language: labelLanguage)]
        }

        // Named, not described, as soon as the reader has picked someone who exists. Sending a
        // description where a uri was available is how a database of this kind fills with
        // twins, and merging two authors is not something a phone can undo.
        //
        // And only for a work being created: one that exists already has its authors. An author
        // seed sent beside an existing work would still be resolved — and, failing that,
        // created — on its own (`create_unresolved_entry.ts`).
        let authors: [EntityResolveRequest.Seed]? = if draft.workUri != nil {
            nil
        } else {
            draft.namedAuthors.map { author -> EntityResolveRequest.Seed in
                if let uri = author.uri {
                    .named(uri)
                } else {
                    .described(label: author.trimmedName, language: labelLanguage)
                }
            }
        }

        return .init(
            entries: [.init(edition: edition, works: works, authors: authors)],
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
