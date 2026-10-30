//
//  UserProfileTab.swift
//  ReCIT_iOS
//
//  The three pages of a reader's profile: their books, their lists, and how they present
//  themselves.
//

import SwiftUI

enum UserProfileTab: CaseIterable, Hashable {
    case inventory
    case lists
    case presentation

    /// The tab's word alone, before its count is known — or for good, on Présentation.
    var title: LocalizedStringKey {
        switch self {
        case .inventory: "nav.inventory"
        case .lists: "nav.lists"
        case .presentation: "user.tab.presentation"
        }
    }
}
