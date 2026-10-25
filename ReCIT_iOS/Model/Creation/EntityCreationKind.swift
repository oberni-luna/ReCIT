//
//  EntityCreationKind.swift
//  ReCIT_iOS
//
//  What an entity created from « Modifier l'édition » is, and so what `POST /api/entities` is
//  sent for it: the class inventaire.io's website gives it (`wdt:P31`), and what else it needs.
//
//  A collection is the odd one: it has no label, its name is a title (`wdt:P1476`, as an
//  edition's), and the website will not create one without its publisher (`wdt:P123`).
//

import Foundation

enum EntityCreationKind: Equatable, Sendable {
    case human
    case publisher
    case collection(publisherUri: String)

    /// The kind of entity the values of `property` are, when one can be created from the form —
    /// `nil` for a language, which is chosen and never created, and for a collection while the
    /// edition names no publisher that exists.
    init?(for property: EditionProperty, publisherUri: String?) {
        switch property.searchType {
        case .humans:
            self = .human
        case .publishers:
            self = .publisher
        case .collections:
            guard let publisherUri else { return nil }
            self = .collection(publisherUri: publisherUri)
        default:
            return nil
        }
    }
}
