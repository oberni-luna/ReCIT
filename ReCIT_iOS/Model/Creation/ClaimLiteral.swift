//
//  ClaimLiteral.swift
//  ReCIT_iOS
//
//  One value of a claim as it travels: a string — a title, a uri, an identifier, a date — or a
//  whole number. inventaire.io validates the type, not only the text: `wdt:P1104`, the number of
//  pages, is a positive integer and the string `"256"` is refused, so a count has to go out as a
//  JSON number.
//
//  Written as a literal in tests and catalogues — `"Lucioles"`, `256` — which is why it is
//  expressible by both.
//

import Foundation

enum ClaimLiteral: Hashable, Sendable, Codable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    case string(String)
    case integer(Int)

    init(stringLiteral value: String) {
        self = .string(value)
    }

    init(integerLiteral value: Int) {
        self = .integer(value)
    }

    /// A value as `by-uris` answers it. A number is kept only when whole — inventaire.io's
    /// numbers are counts — and a boolean is nothing an edition holds.
    init?(_ value: ClaimValue) {
        switch value {
        case .string(let text):
            self = .string(text)
        case .number(let number):
            guard let integer = Int(exactly: number) else { return nil }
            self = .integer(integer)
        case .bool:
            return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container: SingleValueDecodingContainer = try decoder.singleValueContainer()
        if let integer = try? container.decode(Int.self) {
            self = .integer(integer)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container: SingleValueEncodingContainer = encoder.singleValueContainer()
        switch self {
        case .string(let text):
            try container.encode(text)
        case .integer(let integer):
            try container.encode(integer)
        }
    }

    /// The value as the form prints it.
    var text: String {
        switch self {
        case .string(let text): text
        case .integer(let integer): String(integer)
        }
    }

    /// The value when it is a string: a uri, a date, an identifier.
    var string: String? {
        guard case .string(let text) = self else { return nil }
        return text
    }
}
