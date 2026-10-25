//
//  EditableEditionDTO.swift
//  ReCIT_iOS
//
//  The shape of `by-uris` read to open « Modifier l'édition »: the entity's canonical uri and
//  its claims, asked with `attributes=info|claims`. `EntityResultDTO` cannot be reused: it
//  requires labels, which are not asked for here.
//
//  The envelope is keyed by the canonical uri; an `isbn:` uri asked for comes back under the
//  `inv:` one it redirects to, so the entities are read by value, not by the key asked for.
//

import Foundation

struct EditableEditionsDTO: Codable {
    let entities: [String: EditableEditionDTO]
}

struct EditableEditionDTO: Codable {
    let uri: String
    let claims: [String: [ClaimValue]]?

    /// The first string value of a claim. Editions carry one title, one subtitle, one cover.
    func firstValue(of property: String) -> String? {
        claims?[property]?.lazy.compactMap { $0.getStringValue() }.first
    }
}
