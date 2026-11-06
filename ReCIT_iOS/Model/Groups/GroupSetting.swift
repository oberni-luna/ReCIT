//
//  GroupSetting.swift
//  ReCIT_iOS
//
//  What an admin can change about a group, one attribute at a time — the server's `updatable`
//  list, minus `position`, which the app does not offer yet.
//

import Foundation

enum GroupSetting: Equatable, Sendable {
    case name(String)
    case description(String)
    case searchable(Bool)
    case open(Bool)
    /// The path the server filed the picture under, `/img/groups/<hash>` — the only shape it
    /// accepts. `nil` takes the picture away.
    case picture(String?)

    /// `value` is a string, a boolean or `null` on the wire, never an object.
    enum Value: Codable, Equatable, Sendable {
        case text(String)
        case flag(Bool)
        case null

        init(from decoder: Decoder) throws {
            let container: SingleValueDecodingContainer = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let flag = try? container.decode(Bool.self) {
                self = .flag(flag)
            } else {
                self = .text(try container.decode(String.self))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container: SingleValueEncodingContainer = encoder.singleValueContainer()
            switch self {
            case let .text(text): try container.encode(text)
            case let .flag(flag): try container.encode(flag)
            case .null: try container.encodeNil()
            }
        }
    }

    var attribute: String {
        switch self {
        case .name: "name"
        case .description: "description"
        case .searchable: "searchable"
        case .open: "open"
        case .picture: "picture"
        }
    }

    var value: Value {
        switch self {
        case let .name(text), let .description(text): .text(text)
        case let .searchable(flag), let .open(flag): .flag(flag)
        case let .picture(path): path.map(Value.text) ?? .null
        }
    }

    /// The group once the setting is written.
    ///
    /// - Parameter baseUrl: What a picture's path is served under: the group keeps its picture as
    ///   an address to fetch, the server as a path.
    func applied(
        to group: ReaderGroup,
        baseUrl: String
    ) -> ReaderGroup {
        var group: ReaderGroup = group
        switch self {
        case let .name(name): group.name = name
        case let .description(description): group.description = description
        case let .searchable(searchable): group.searchable = searchable
        case let .open(open): group.open = open
        case let .picture(path): group.pictureURL = AbsoluteImageURL.resolve(path, baseUrl: baseUrl)
        }
        return group
    }
}
