//
//  WorkSummaryDTO.swift
//  ReCIT_iOS
//
//  The slim shape of `by-uris` read to complete a work search: labels and claims, nothing else.
//  The same envelope carries the works and — asked with `relatives=wdt:P50` — their authors, so
//  one type decodes both: a work is read for its `wdt:P50` and `wdt:P577`, an author for its
//  label.
//
//  `EntityResultDTO` cannot be reused: it requires `type` and `descriptions`, which are not
//  asked for here. See PRD 0026.
//

import Foundation

struct WorkSummariesDTO: Codable {
    let entities: [String: WorkSummaryDTO]
}

struct WorkSummaryDTO: Codable {
    let uri: String
    let labels: [String: String]?
    let claims: [String: [ClaimValue]]?

    /// The name to show, by the same preference every other label in the app follows.
    var label: String? {
        EntityLabel.resolve(labels)
    }

    /// The string values of one claim — uris for `wdt:P50`, dates for `wdt:P577`.
    func values(of property: WikidataProperty) -> [String] {
        claims?[property.rawValue]?.compactMap { $0.getStringValue() } ?? []
    }
}
