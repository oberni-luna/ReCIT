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
    /// One of the screens of the catalogue's properties.
    case property(EditionPropertyStep)
}
