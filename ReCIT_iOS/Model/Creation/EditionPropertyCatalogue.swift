//
//  EditionPropertyCatalogue.swift
//  ReCIT_iOS
//
//  Which properties a form shows: an edition's, a work's or a person's. A uri means a property
//  only within its catalogue — a work's `wdt:P407` is its original language, an edition's is the
//  language it is printed in — so a form's values (`EditionProperties`) carry theirs, and the
//  screens a property pushes look the uri up there.
//

import Foundation

extension EditionProperty {

    enum Catalogue: Hashable, Sendable {
        case edition
        case work
        case human

        /// Every property of the catalogue, in the order the form shows them.
        var properties: [EditionProperty] {
            switch self {
            case .edition: EditionProperty.all
            case .work: EditionProperty.workProperties
            case .human: EditionProperty.humanProperties
            }
        }

        func property(named uri: String) -> EditionProperty? {
            properties.first { $0.uri == uri }
        }

        func properties(in group: Group) -> [EditionProperty] {
            properties.filter { $0.group == group }
        }

        /// The catalogue of an entity of `type`, as `by-uris` answers it with `info`.
        init?(entityType type: String?) {
            switch type {
            case "edition": self = .edition
            case "work": self = .work
            case "human": self = .human
            default: return nil
            }
        }
    }
}
