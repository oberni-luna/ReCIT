//
//  UserProfileTab.swift
//  ReCIT_iOS
//
//  The four pages of a reader's profile: their books, their lists, the Échanges between us, and
//  how they present themselves.
//

import SwiftUI

enum UserProfileTab: CaseIterable, Hashable {
    case inventory
    case lists
    case transactions
    case presentation

    /// The tab's word alone, before its count is known — or for good, on Présentation.
    var title: LocalizedStringKey {
        switch self {
        case .inventory: "nav.inventory"
        case .lists: "nav.lists"
        case .transactions: "user.tab.transactions"
        case .presentation: "user.tab.presentation"
        }
    }

    /// The pages of a profile whose books are open to me. No Échanges on my own: there is no
    /// Échange with oneself.
    static func pages(isMine: Bool) -> [UserProfileTab] {
        isMine ? allCases.filter { $0 != .transactions } : allCases
    }
}
