//
//  GroupSetting.swift
//  ReCIT_iOS
//
//  What an admin can change about a group, one attribute at a time — the server's `updatable`
//  list, minus `picture` and `position`, which the app does not offer yet.
//

import Foundation

enum GroupSetting: Equatable, Sendable {
    case name(String)
    case description(String)
    case searchable(Bool)
    case open(Bool)

    var attribute: String {
        switch self {
        case .name: "name"
        case .description: "description"
        case .searchable: "searchable"
        case .open: "open"
        }
    }

    var value: Value {
        switch self {
        case .name(let text), .description(let text): .text(text)
        case .searchable(let flag), .open(let flag): .flag(flag)
        }
    }

    /// The group once the setting is written.
    func applied(to group: ReaderGroup) -> ReaderGroup {
        var group: ReaderGroup = group
        switch self {
        case .name(let name): group.name = name
        case .description(let description): group.description = description
        case .searchable(let searchable): group.searchable = searchable
        case .open(let open): group.open = open
        }
        return group
    }

    /// `value` is a string or a boolean on the wire, never an object.
    enum Value: Codable, Equatable, Sendable {
        case text(String)
        case flag(Bool)

        func encode(to encoder: Encoder) throws {
            var container: SingleValueEncodingContainer = encoder.singleValueContainer()
            switch self {
            case .text(let text): try container.encode(text)
            case .flag(let flag): try container.encode(flag)
            }
        }

        init(from decoder: Decoder) throws {
            let container: SingleValueDecodingContainer = try decoder.singleValueContainer()
            if let flag = try? container.decode(Bool.self) {
                self = .flag(flag)
            } else {
                self = .text(try container.decode(String.self))
            }
        }
    }
}
