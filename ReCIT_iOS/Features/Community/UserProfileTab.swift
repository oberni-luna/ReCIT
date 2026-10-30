//
//  UserProfileTab.swift
//  ReCIT_iOS
//
//  The two halves of a reader's profile under their étagères: their books, and their lists.
//

import SwiftUI

enum UserProfileTab: CaseIterable, Hashable {
    case inventory
    case lists

    var title: LocalizedStringKey {
        switch self {
        case .inventory: "nav.inventory"
        case .lists: "nav.lists"
        }
    }
}
