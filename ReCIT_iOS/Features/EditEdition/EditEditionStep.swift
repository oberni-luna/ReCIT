//
//  EditEditionStep.swift
//  ReCIT_iOS
//
//  What « Modifier l'édition » can push over its form: the search for the edition's work, the
//  search for an author to add to it, the cover from an address on the web, and the screens of
//  the catalogue's properties — an entity's values and search, the date, the identifiers.
//

import Foundation

enum EditEditionStep: Hashable {
    case work
    case author
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
