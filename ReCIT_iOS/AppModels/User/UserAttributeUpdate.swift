//
//  UserAttributeUpdate.swift
//  ReCIT_iOS
//
//  The body of `PUT /api/user`: one attribute, one value. A nil value is sent as an explicit
//  `null` — that is how `picture` and `position` are taken away — where the synthesized encoding
//  would have left the key out and the server would have answered « missing value ».
//

import Foundation

struct UserAttributeUpdate<Value: Codable>: Codable {
    let attribute: String
    let value: Value

    enum CodingKeys: String, CodingKey {
        case attribute
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attribute, forKey: .attribute)
        try container.encode(value, forKey: .value)
    }
}
