//
//  EditableEditionDTO.swift
//  ReCIT_iOS
//
//  The shape of `by-uris` read to open « Modifier l'édition »: the edition's canonical uri, its
//  type and claims, and — in the same envelope, asked as relatives — the publishers, collections
//  and people its claims name, with their labels. `EntityResultDTO` cannot be reused: it requires
//  labels, which an edition does not have.
//
//  The envelope is keyed by the canonical uri; an `isbn:` uri asked for comes back under the
//  `inv:` one it redirects to, which `redirects` says.
//

import Foundation

struct EditableEditionsDTO: Codable {
    let entities: [String: EditableEditionDTO]
    let redirects: [String: String]?
}

struct EditableEditionDTO: Codable {
    let uri: String
    /// `edition`, `collection`… — asked with `info`.
    let type: String?
    /// The language the entity's labels were first written in — asked with `info`.
    let originalLang: String?
    let labels: [String: String]?
    let claims: [String: [ClaimValue]]?

    /// The first string value of a claim. Editions carry one title, one subtitle, one cover.
    func firstValue(of property: String) -> String? {
        claims?[property]?.lazy.compactMap { $0.getStringValue() }.first
    }

    /// The name the form shows for this entity: its label, or — for a collection, which has
    /// none — its title.
    var displayName: String? {
        EntityLabel.resolve(labels, originalLang: originalLang)
            ?? firstValue(of: WikidataProperty.title.rawValue)
    }
}
