//
//  EditionTitle.swift
//  ReCIT_iOS
//
//  The name an edition will actually wear on screen — asked once, by everything that needs it.
//
//  It exists because two places were answering the same question differently, and the screen
//  believed the wrong one. `Edition.init(entityDto:)` read `labels["fromclaims"]` and fell back
//  to the literal `"Unknown"`; `EditionRelevance`'s candidates were built from the `wdt:P1476`
//  claim. Those are not the same test, and the gap is not small: of 513 editions sampled across
//  14 works on 2026-09-11, **66 carried the claim and no `fromclaims` label**. Every one of them
//  passed the ranking's "has a title" filter and then rendered as `Unknown`.
//
//  The reason is that inventaire.io synthesises `fromclaims` for the editions it holds itself
//  (`inv:`), while editions mirrored from Wikidata (`wd:`) arrive with their title under the
//  multilingual `mul` label instead. `wd:Q137643134` is called *Dune* in both — under `mul` and
//  under `wdt:P1476` — and the app called it `Unknown`.
//
//  So the order below is not a preference, it is three spellings of one fact, most specific
//  first: what inventaire.io built for its own entity, then the multilingual label Wikidata
//  ships, then the raw claim they are both derived from.
//
//  `nil` means the edition genuinely has no name to show. That is the value a redirect must
//  never land on (ADR 0002, Move 3).
//

import Foundation

enum EditionTitle {
    /// The title to display for an edition entity, or `nil` when it has none.
    static func resolve(
        labels: [String: String]?,
        claims: [String: [ClaimValue]]?
    ) -> String? {
        let spellings: [String?] = [
            labels?["fromclaims"],
            labels?["mul"],
            claims?[WikidataProperty.title.rawValue]?.first?.getStringValue()
        ]

        for case let spelling? in spellings where spelling.isEmpty == false {
            return spelling
        }

        return nil
    }
}
