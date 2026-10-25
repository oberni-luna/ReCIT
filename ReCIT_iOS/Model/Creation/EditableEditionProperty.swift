//
//  EditableEditionProperty.swift
//  ReCIT_iOS
//
//  The three claims of an edition that « Modifier l'édition » can change: its title, its
//  subtitle, its cover. The rest of what inventaire.io knows about an edition — its work, its
//  publisher, its date — is left to the website.
//
//  `invp:P2` is not a Wikidata property: it is inventaire.io's own, and holds the hash a cover
//  was filed under, never a url.
//

import Foundation

enum EditableEditionProperty: String, Codable, Sendable {
    case title = "wdt:P1476"
    case subtitle = "wdt:P1680"
    case cover = "invp:P2"
}
