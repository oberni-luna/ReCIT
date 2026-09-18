//
//  EntityResolveRequest.swift
//  ReCIT_iOS
//
//  The body of `POST /api/entities/resolve` — the one endpoint that carries the whole of
//  creating a book on inventaire.io.
//
//  An entry is three seeds: the edition, the works it is an edition of, and their authors.
//  Each seed either **names** an entity by its uri, or **describes** one by its labels and
//  claims. That distinction is the whole contract: a uri is reused, a description is matched
//  and, failing a match, created. Sending a description where a uri was available is how a
//  database of this kind fills with duplicates.
//
//  Optional fields are omitted rather than sent null — Swift's synthesized encoding does that
//  for us — because the server reads a present key as an intention.
//
//  Verified against `https://inventaire.io/public/api_specs.json` and the Codeberg source on
//  2026-09-18. See PRD 0015.
//

import Foundation

struct EntityResolveRequest: Codable, Equatable, Sendable {

    let entries: [Entry]

    /// Create what could not be resolved. False for the reconnaissance pass that only asks
    /// what inventaire already knows.
    let create: Bool

    /// Let the server go looking for what it can add by itself — a cover, from the ISBN.
    let enrich: Bool

    /// Refuse the whole entry rather than half-creating it.
    let strict: Bool

    struct Entry: Codable, Equatable, Sendable {
        let edition: Seed
        let works: [Seed]?
        let authors: [Seed]?
    }

    /// A seed is a uri **or** a description, never usefully both.
    struct Seed: Codable, Equatable, Sendable {
        var uri: String?
        var labels: [String: String]?
        var claims: [String: [String]]?
        /// Only an edition seed carries one: the url of a cover the server should attach. Ours
        /// is the one it has just been handed by the upload; without it, `enrich` goes looking
        /// for one from the ISBN.
        var image: String?

        static func named(_ uri: String) -> Seed {
            .init(uri: uri)
        }

        static func described(label: String, language: String, claims: [String: [String]]? = nil) -> Seed {
            .init(labels: [language: label], claims: claims)
        }
    }
}
