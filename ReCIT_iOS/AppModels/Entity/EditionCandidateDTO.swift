//
//  EditionCandidateDTO.swift
//  ReCIT_iOS
//
//  The lean shape `WorkEditionResolver` reads. It decodes the same `by-uris` envelope as
//  `EntityResultDTO` but keeps only what choosing an edition needs — the uri, the language, the
//  title claim and the cover — so a work with 127 editions costs one decode of four fields each
//  rather than a full entity graph nobody is going to persist.
//
//  See PRD 0014.
//

import Foundation

struct EditionCandidatesDTO: Codable {
    let entities: [String: EditionCandidateDTO]
}

struct EditionCandidateDTO: Codable {
    let uri: String
    /// ISO code of this edition's own language — inventaire.io derives it from `wdt:P407`, and a
    /// French edition reports `"fr"`. Only returned when `attributes` includes `info`.
    let originalLang: String?
    let labels: [String: String]?
    let image: EntityImageDTO?
    let claims: [String: [ClaimValue]]?

    /// Whether this edition has a name to show — asked through `EditionTitle`, the same
    /// resolution `Edition` itself uses, so the ranking cannot judge an edition titled while the
    /// screen renders it `Unknown`. That divergence is exactly what this property used to cause
    /// by reading the `wdt:P1476` claim directly.
    ///
    /// Not whether the title resembles the work's — see `EditionRelevance` for why the
    /// resemblance is the wrong rule.
    var hasTitle: Bool {
        EditionTitle.resolve(labels: labels, claims: claims) != nil
    }

    /// Whether this edition is one book rather than a box of several. `wdt:P629` — the claim
    /// `reverse-claims` was queried on — lists every work the edition is of, so an omnibus names
    /// them all and a novel names one.
    var isSingleWork: Bool {
        (claims?[WikidataProperty.editionOf.rawValue]?.count ?? 1) <= 1
    }

    /// Whether the entity carries a cover. `image.url` is what `by-uris` resolves `invp:P2` into,
    /// and it is the same field every other mapping in the app reads.
    var hasCover: Bool {
        guard let url = image?.url else { return false }
        return url.isEmpty == false
    }
}
