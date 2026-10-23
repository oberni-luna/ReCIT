//
//  AvatarKind.swift
//  ReCIT_iOS
//
//  Who an avatar stands for, which decides its shape and what it shows without a picture
//  (PRD 0019, Q21): a reader is a disc with their initials, a group a rounded square with the
//  `person.2` glyph. A group is never a circle — it should never be read as a person at a glance —
//  and the shape follows from the kind, so no call site can draw one.
//

import Foundation

nonisolated enum AvatarKind: Hashable, Sendable {
    case reader(username: String)
    case group

    /// A disc for a reader, a rounded square for a group.
    var isRound: Bool {
        switch self {
        case .reader: true
        case .group: false
        }
    }

    /// The letters drawn without a photo; `nil` for a group, which is drawn with a glyph.
    var initials: String? {
        switch self {
        case .reader(let username): ReaderInitials.of(username)
        case .group: nil
        }
    }
}
