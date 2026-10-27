//
//  EditionBibliographicClaims.swift
//  ReCIT_iOS
//
//  What tells two editions of one work apart, read off an edition's claims: its ISBN, its
//  publisher and collection, its date, its page count, and the editions it has been declared
//  different from. The line under the title of « Éditions », and the facts the duplicate
//  detection works from.
//
//  The ISBN is `wdt:P212` (ISBN-13) as the server writes it, hyphens included, because that is
//  what is printed on the book; failing that `wdt:P957` (ISBN-10), so a book that has one never
//  reads « Sans ISBN ».
//
//  Every field is `nil` (or empty) when the claim is absent, and `Edition.update(entityDto:)`
//  reads that as « not said », never as « removed ». See PRD 0028.
//

import Foundation

struct EditionBibliographicClaims: Equatable {
    let isbn: String?
    let publisherUri: String?
    let collectionUri: String?
    let publicationDate: String?
    let numberOfPages: Int?
    let differentFromUris: [String]

    init(claims: [String: [ClaimValue]]) {
        func first(_ property: WikidataProperty) -> String? {
            claims[property.rawValue]?.lazy.compactMap { $0.getStringValue() }.first { $0.isEmpty == false }
        }

        isbn = first(.isbn13) ?? first(.isbn10)
        publisherUri = first(.publisher)
        collectionUri = first(.collection)
        publicationDate = first(.publicationDate)
        numberOfPages = claims[WikidataProperty.numberOfPages.rawValue]?.lazy
            .compactMap { $0.getNumberValue() ?? $0.getStringValue().flatMap(Double.init) }
            .first
            .map { Int($0) }
        differentFromUris = claims[WikidataProperty.differentFrom.rawValue]?.compactMap { $0.getStringValue() } ?? []
    }

    /// The year of a publication date — `1995` from `1995`, `1995-03` or `1995-03-01`.
    static func year(of publicationDate: String?) -> String? {
        guard let publicationDate else { return nil }
        let year: Substring = publicationDate.prefix { $0 != "-" }
        guard year.isEmpty == false, year.allSatisfy(\.isNumber) else { return nil }
        return String(year)
    }
}
