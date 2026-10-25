//
//  EditionPropertyStep.swift
//  ReCIT_iOS
//
//  The screens a property of the catalogue pushes over the edition's form — the same in « Modifier
//  l'édition » and in the scanner's « Nouvelle édition », whose navigation stacks each wrap them
//  in a step of their own.
//

import Foundation

enum EditionPropertyStep: Hashable {
    /// The entities one property names, to take some away or add one.
    case values(property: String)
    /// The search for an entity to add to a property.
    case picker(property: String)
    case publicationDate
    /// The catalogues an identifier — or the kinds of links — can be added to.
    case identifierCatalog(EditionProperty.Group)
    /// Typing one identifier or link.
    case identifierInput(property: String)

    /// What touching `property` pushes: the date's screen, or — for an entity — the list of its
    /// values, or the search straight away when there are none.
    static func opening(_ property: EditionProperty, in properties: EditionProperties) -> EditionPropertyStep {
        if property == .publicationDate { return .publicationDate }
        if properties.entities(of: property).isEmpty == false { return .values(property: property.uri) }
        return .picker(property: property.uri)
    }
}
