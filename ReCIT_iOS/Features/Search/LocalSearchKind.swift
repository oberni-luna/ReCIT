//
//  LocalSearchKind.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// What one of Recherche's local sections finds, and so where its « Tout voir » leads.
enum LocalSearchKind: String, Sendable {
    /// My books and my friends' copies, « Dans mes livres et chez mes ami·es ».
    case books
    case lists
    case friends
    case groups

    /// The section's header, and the title of the screen behind its « Tout voir ».
    var title: LocalizedStringKey {
        switch self {
        case .books: "inventory.search.local_section"
        case .lists: "inventory.search.section.lists"
        case .friends: "inventory.search.section.friends"
        case .groups: "inventory.search.section.groups"
        }
    }

    /// The identifier of the section's « Tout voir ».
    var seeAllAccessibilityID: String {
        switch self {
        case .books: "e2e.searchLocal.seeAll"
        case .lists: "e2e.searchList.seeAll"
        case .friends: "e2e.searchFriend.seeAll"
        case .groups: "e2e.searchGroup.seeAll"
        }
    }
}
