//
//  GenreClaims.swift
//  ReCIT_iOS
//
//  Which claims on a work count as its genre, and what to do when they disagree.
//
//  The backfill originally read `wdt:P136` (genre) and nothing else, which is right for a work
//  mapped to Wikidata and useless for one that only exists in inventaire: measured against the
//  live API, `wd:` works almost always carry a genre while `inv:` works carry `wdt:P31` and
//  little else — sometimes `wdt:P921` (main subject), never `wdt:P136`. Recent and
//  French-language titles are exactly the ones that stay `inv:`-only, so a library of them
//  answered "no genre anywhere" and the arrangement had nothing to work with. See issue 0034.
//
//  Subjects are a **fallback, not a peer**. A subject describes what a book is about, a genre
//  what kind of book it is, and they are not interchangeable: one work above answers
//  "capitalisme" and "figure d'autorité", which would have the model naming a shelf after a
//  theme rather than a kind. Mixing the two into one pool would also let a work with a real
//  genre be pulled towards its subject, which is a regression for the half of the library that
//  was already working. So a work uses its genres when it has any, and its subjects only when
//  it has none — where the choice is between a thematic shelf and no shelf at all.
//
//  Pure on purpose, and separate from the model that fetches: this is the rule, and the rule is
//  what changed. See PRD 0006.
//

import Foundation

enum GenreClaims {

    /// Genre. Present on virtually every Wikidata-mapped work, absent from inventaire's own.
    static let genreProperty: String = WikidataProperty.genre.rawValue

    /// Main subject. What an `inv:` work carries instead, when it carries anything.
    static let subjectProperty: String = WikidataProperty.mainSubject.rawValue

    /// Which reading of the claims produced a work's stored genres.
    ///
    /// Bumped when the rule below changes, and recorded on each work, because the enrichment
    /// timestamp alone cannot express "asked, but under the old question". Without it, every
    /// work already asked under the genre-only rule would keep its empty list for good and this
    /// fix would not reach the libraries that reported it.
    static let revision: Int = 2

    /// The uris to resolve into labels for one work, from its claims' string values.
    ///
    /// - Parameters:
    ///   - genres: values of `wdt:P136`.
    ///   - subjects: values of `wdt:P921`.
    /// - Returns: the genres, deduplicated in order; or the subjects when there are no genres.
    static func uris(genres: [String], subjects: [String]) -> [String] {
        let candidates: [String] = genres.isEmpty ? subjects : genres

        var seen: Set<String> = []
        return candidates.filter { seen.insert($0).inserted }
    }
}
