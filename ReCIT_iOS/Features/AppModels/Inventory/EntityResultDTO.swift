//
//  EntityResultDTO.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/12/2025.
//

import Foundation

struct EntityResultsDTO: Codable {
    let entities: [String : EntityResultDTO]
}

struct EntityResultDTO: Codable {
    let uri: String
    let lastrevid: Int?
    let type: String
    let originalLang: String?
    let labels: [String: String]
    let descriptions: [String: String]?
    let image: EntityImageDTO?
    let claims: [String: [ClaimValue]]
}

struct EntityImageDTO: Codable {
    let url: String
    let file: String?
    let credit: EntityImageCreditDTO?
}

struct EntityImageCreditDTO: Codable {
    let text: String
    let url: String
}

enum ClaimValue: Codable {
    case string(String)
    case bool(Bool)
    case number(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let v = try? container.decode(String.self) {
            self = .string(v)
            return
        }
        if let v = try? container.decode(Double.self) {
            self = .number(v)
            return
        }
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
            return
        }
        throw DecodingError.typeMismatch(
            ClaimValue.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Type is not matched", underlyingError: nil))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }

    func getStringValue() -> String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }

    func getNumberValue() -> Double? {
        switch self {
        case .number(let value):
            return value
        default:
            return nil
        }
    }
}

