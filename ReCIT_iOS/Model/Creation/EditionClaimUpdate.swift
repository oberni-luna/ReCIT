//
//  EditionClaimUpdate.swift
//  ReCIT_iOS
//
//  One change to one claim — of the edition, or of one of its works — as
//  `PUT /api/entities/update-claim` takes it: the value it replaces and the value it puts in its
//  place.
//
//  Either side can be missing, and is then **left out** of the body rather than sent as `null`:
//  no old value adds a claim the entity did not have, no new value removes the claim. The
//  server reads an empty string the same way, but an absent key says it without relying on that.
//
//  The values keep their type: a number of pages goes out as a JSON number, which is what the
//  server validates (`ClaimLiteral`).
//

import Foundation

struct EditionClaimUpdate: Codable, Equatable, Sendable {
    let uri: String
    /// The property's uri, `wdt:P123`.
    let property: String
    let oldValue: ClaimLiteral?
    let newValue: ClaimLiteral?

    enum CodingKeys: String, CodingKey {
        case uri
        case property
        case oldValue = "old-value"
        case newValue = "new-value"
    }

    init(
        uri: String,
        property: String,
        oldValue: ClaimLiteral?,
        newValue: ClaimLiteral?
    ) {
        self.uri = uri
        self.property = property
        self.oldValue = oldValue
        self.newValue = newValue
    }

    /// One of the claims the form has always changed — a title, a cover, a work, an author —
    /// whose values are strings.
    init(
        uri: String,
        property: EditableClaimProperty,
        oldValue: String?,
        newValue: String?
    ) {
        self.init(
            uri: uri,
            property: property.rawValue,
            oldValue: oldValue.map(ClaimLiteral.string),
            newValue: newValue.map(ClaimLiteral.string)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uri, forKey: .uri)
        try container.encode(property, forKey: .property)
        try container.encodeIfPresent(oldValue, forKey: .oldValue)
        try container.encodeIfPresent(newValue, forKey: .newValue)
    }
}
