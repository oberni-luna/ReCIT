//
//  WdtProperties.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 02/12/2025.
//

import Foundation

enum WikidataProperty: String {
    // Works
    case instanceOf              = "wdt:P31"   // instance of
    case genre                   = "wdt:P136"  // genre
    case publicationDate         = "wdt:P577"  // publication date
    case openLibraryID           = "wdt:P648"  // Open Library ID
    case author                  = "wdt:P50"   // Author
    case isbn13                  = "wdt:P212"  // ISBN-13
    case isbn10                  = "wdt:P957"  // ISBN-10
    case title                   = "wdt:P1476" // title
    case editionOf               = "wdt:P629"  // edition or translation of
    case publisher               = "wdt:P123"  // publisher
    case collection              = "wdt:P195"  // collection
    case numberOfPages           = "wdt:P1104" // number of pages
    case goodreadsEditionID      = "wdt:P2969" // Goodreads version/edition ID
    case series                  = "wdt:P179"  // series

    // Identifiers / authority fileswdt:
    case isni                    = "wdt:P213"  // International Standard Name Identifier
    case viaf                    = "wdt:P214"  // Virtual International Authority File
    case gnd                     = "wdt:P227"  // international authority file identifier

    // Person metadatawdt:
    case dateOfBirth             = "wdt:P569"  // date of birth
    case dateOfDeath             = "wdt:P570"  // date of death
    case officialWebsite         = "wdt:P856"  // official website
    case occupation              = "wdt:P106"  // occupation
    case award                   = "wdt:P166"  // award received

    // Media / miscwdt:
    case image                   = "wdt:P18"   // image
    case educatedAt              = "wdt:P69"   // educated at
    case signature               = "wdt:P109"  // signature

    var description: String {
        switch self {
        case .instanceOf: return "instance of"
        case .genre: return "genre"
        case .publicationDate: return "publication date"
        case .openLibraryID: return "Open Library ID"
        case .author: return "Author"
        case .isbn13: return "ISBN-13"
        case .isbn10: return "ISBN-10"
        case .title: return "title"
        case .editionOf: return "edition or translation of"
        case .publisher: return "publisher"
        case .collection: return "collection"
        case .numberOfPages: return "number of pages"
        case .goodreadsEditionID: return "Goodreads version/edition ID"
        case .series: return "series"

        case .isni: return "International Standard Name Identifier"
        case .viaf: return "Virtual International Authority File"
        case .gnd: return "International authority file identifier"

        case .dateOfBirth: return "date of birth"
        case .dateOfDeath: return "date of death"
        case .officialWebsite: return "official website"
        case .occupation: return "occupation"
        case .award: return "award received"

        case .image: return "image"
        case .educatedAt: return "educated at"
        case .signature: return "signature"
        }
    }
}
