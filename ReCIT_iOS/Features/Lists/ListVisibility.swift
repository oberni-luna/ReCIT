//
//  ListVisibility.swift
//  ReCIT_iOS
//
//  The five answers to « Visible par » a list can be given, both ways: read from inventaire.io's
//  visibility keys, and written back as them. Five because the Présentation tab names five, so
//  whatever the form writes reads back in the same words; the étagère's `FormVisibility` has
//  three because étagères have no groups.
//
//  inventaire.io also accepts a key per group (`group:<id>`). The store already drops those
//  keys when it decodes a list, so the form neither offers them nor keeps them.
//

import Foundation

enum ListVisibility: CaseIterable, Identifiable {
    case `private`
    case friends
    case groups
    case friendsAndGroups
    case `public`

    var id: Self { self }

    /// `public` wins over the rest: a list everyone may see is not made more visible by the
    /// friends and groups keys that may sit next to it.
    init(attributes: [VisibilityAttributes]) {
        if attributes.contains(.public) {
            self = .public
            return
        }

        switch (attributes.contains(.friends), attributes.contains(.groups)) {
        case (true, true): self = .friendsAndGroups
        case (true, false): self = .friends
        case (false, true): self = .groups
        case (false, false): self = .private
        }
    }

    var attributes: [VisibilityAttributes] {
        switch self {
        case .private: []
        case .friends: [.friends]
        case .groups: [.groups]
        case .friendsAndGroups: [.friends, .groups]
        case .public: [.public]
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .private: "list.visibility.private"
        case .friends: "list.visibility.friends"
        case .groups: "list.visibility.groups"
        case .friendsAndGroups: "list.visibility.friends_and_groups"
        case .public: "list.visibility.public"
        }
    }
}
