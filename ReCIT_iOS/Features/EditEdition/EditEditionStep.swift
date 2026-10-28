//
//  EditEditionStep.swift
//  ReCIT_iOS
//
//  What « Modifier l'édition » can push over its form: the search for a work to add, « Modifier
//  l'œuvre » and its author search, the cover from an address on the web, and the screens of the
//  catalogue's properties — an entity's values and search, the date, the identifiers. And, for
//  a work or a person inventaire.io has, « Modifier l'œuvre » and « Modifier l'auteur·ice »
//  with the screens of their own properties.
//

import Foundation

enum EditEditionStep: Hashable {
    /// The search for a work to add.
    case work
    /// « Modifier l'œuvre » for the work with this id.
    case workDetail(id: UUID)
    /// The search for an author to add to the work with this id.
    case workAuthor(id: UUID)
    case coverFromURL
    /// One of the screens of the catalogue's properties.
    case property(EditionPropertyStep)
    /// « Modifier l'œuvre » or « Modifier l'auteur·ice » for the entity with this uri.
    case entity(uri: String)
    /// One of the screens of the properties of the entity with this uri.
    case entityProperty(uri: String, step: EditionPropertyStep)
}
