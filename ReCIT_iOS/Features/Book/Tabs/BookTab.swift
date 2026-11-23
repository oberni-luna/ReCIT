//
//  BookTab.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

/// The three pages of the Fiche livre: the book itself, my copy and my lists, and what my
/// network holds of it.
enum BookTab: CaseIterable, Hashable {
    case presentation
    case myCopy
    case network

    /// What a test finds the tab's capsule by.
    var accessibilityID: String {
        switch self {
        case .presentation: "e2e.book.tab.presentation"
        case .myCopy: "e2e.book.tab.myCopy"
        case .network: "e2e.book.tab.network"
        }
    }
}
