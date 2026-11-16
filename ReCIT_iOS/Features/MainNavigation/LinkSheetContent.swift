//
//  LinkSheetContent.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

/// What an Ex-libris link opens in a sheet of its own, over a modal that covers the tabs.
enum LinkSheetContent: Equatable {
    /// The screen the link names, at the root of the sheet's own stack.
    case destination(NavigationDestination)
    /// The Profil sheet, for a link to my own username.
    case profile
}
