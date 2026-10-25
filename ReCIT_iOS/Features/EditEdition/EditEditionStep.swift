//
//  EditEditionStep.swift
//  ReCIT_iOS
//
//  What « Modifier l'édition » can push over its form: the search for a work to add, « Modifier
//  l'œuvre » and its author search, the cover from an address on the web, and the screens of the
//  catalogue's properties — an entity's values and search, the date, the identifiers.
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
    /// The entities one property names, to take some away or add one.
    case values(property: String)
    /// The search for an entity to add to a property.
    case picker(property: String)
    case publicationDate
    /// The catalogues an identifier — or the kinds of links — can be added to.
    case identifierCatalog(EditionProperty.Group)
    /// Typing one identifier or link.
    case identifierInput(property: String)
}
