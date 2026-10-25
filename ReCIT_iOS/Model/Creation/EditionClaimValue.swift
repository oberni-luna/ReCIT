//
//  EditionClaimValue.swift
//  ReCIT_iOS
//
//  One value of an edition's property as the form holds it: a literal — a date, a count, an
//  identifier, a format's uri — or an entity, which carries the name the form shows beside the
//  uri the claim sends.
//

import Foundation

enum EditionClaimValue: Hashable, Sendable {
    case literal(ClaimLiteral)
    case entity(EditionEntityValue)

    /// What goes on the wire. `nil` for an entity still to be created: there is no uri to send
    /// until it exists.
    var claim: ClaimLiteral? {
        switch self {
        case .literal(let literal): literal
        case .entity(let entity): entity.uri.map(ClaimLiteral.string)
        }
    }

    var entity: EditionEntityValue? {
        guard case .entity(let entity) = self else { return nil }
        return entity
    }
}
