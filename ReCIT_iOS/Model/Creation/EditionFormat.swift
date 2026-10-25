//
//  EditionFormat.swift
//  ReCIT_iOS
//
//  The six values inventaire.io lets an edition's `wdt:P437` take — the website's shortlist in
//  `allowed_values_per_type_per_property.ts` —, each a Wikidata uri.
//

import Foundation

enum EditionFormat: String, CaseIterable, Identifiable, Sendable {
    case paperback = "wd:Q193934"
    case hardback = "wd:Q193955"
    case pocket = "wd:Q17994250"
    case comicAlbum = "wd:Q2831984"
    case ebook = "wd:Q128093"
    case audiobook = "wd:Q106833"

    var id: String { rawValue }

    var name: LocalizedStringResource {
        switch self {
        case .paperback: "edition_format.paperback"
        case .hardback: "edition_format.hardback"
        case .pocket: "edition_format.pocket"
        case .comicAlbum: "edition_format.comic_album"
        case .ebook: "edition_format.ebook"
        case .audiobook: "edition_format.audiobook"
        }
    }
}
