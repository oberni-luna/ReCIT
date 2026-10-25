//
//  EditableClaimProperty.swift
//  ReCIT_iOS
//
//  The claims « Modifier l'édition » can change. On the edition: its title, its subtitle, its
//  cover, and the work it is an edition of. On that work: its authors, which can be added to.
//  The rest of what an edition says — publisher, date, format, contributors, identifiers — is
//  the catalogue's (`EditionProperty`), named by its uri.
//
//  `invp:P2` is not a Wikidata property: it is inventaire.io's own, and holds the hash a cover
//  was filed under, never a url.
//

import Foundation

enum EditableClaimProperty: String, Codable, Sendable {
    case title = "wdt:P1476"
    case subtitle = "wdt:P1680"
    case cover = "invp:P2"
    /// Edition or translation of — the work, on the edition.
    case work = "wdt:P629"
    /// Author — on the work.
    case author = "wdt:P50"
}
