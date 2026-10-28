//
//  EditionPropertyStep.swift
//  ReCIT_iOS
//
//  The screens a property of the catalogue pushes over the edition's form — the same in « Modifier
//  l'édition » and in the scanner's « Nouvelle édition », whose navigation stacks each wrap them
//  in a step of their own — and in « Modifier l'œuvre » and « Modifier l'auteur·ice », which push
//  them for a work's or a person's properties. A step names its property by uri: the screen
//  looks it up in the catalogue of the values it writes into.
//

import Foundation

enum EditionPropertyStep: Hashable {
    /// The entities one property names, to take some away or add one.
    case values(property: String)
    /// The search for an entity to add to a property.
    case picker(property: String)
    /// The date of a property whose value is one: an edition's publication, a person's birth.
    case date(property: String)
    /// The list a property's value is chosen in, when it is too long for a menu: a work's form.
    case choice(property: String)
    /// The catalogues an identifier — or the kinds of links — can be added to.
    case identifierCatalog(EditionProperty.Group)
    /// Typing one identifier or link.
    case identifierInput(property: String)

    /// What touching `property` pushes: the date's screen, the list of choices, or — for an
    /// entity — the list of its values, or the search straight away when there are none.
    static func opening(_ property: EditionProperty, in properties: EditionProperties) -> EditionPropertyStep {
        if property.kind == .date { return .date(property: property.uri) }
        if property.choices.isEmpty == false { return .choice(property: property.uri) }
        if properties.entities(of: property).isEmpty == false { return .values(property: property.uri) }
        return .picker(property: property.uri)
    }
}
