//
//  EditionClaimUpdate.swift
//  ReCIT_iOS
//
//  One change to one claim — of the edition, or of its work — as `PUT /api/entities/update-claim`
//  takes it: the value it replaces and the value it puts in its place.
//
//  Either side can be missing, and is then **left out** of the body rather than sent as `null`:
//  no old value adds a claim the entity did not have, no new value removes the claim. The
//  server reads an empty string the same way, but an absent key says it without relying on that.
//

import Foundation

struct EditionClaimUpdate: Codable, Equatable, Sendable {
    let uri: String
    let property: EditableClaimProperty
    let oldValue: String?
    let newValue: String?

    enum CodingKeys: String, CodingKey {
        case uri
        case property
        case oldValue = "old-value"
        case newValue = "new-value"
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uri, forKey: .uri)
        try container.encode(property, forKey: .property)
        try container.encodeIfPresent(oldValue, forKey: .oldValue)
        try container.encodeIfPresent(newValue, forKey: .newValue)
    }
}
