//
//  LinkSheetContent.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

/// What an Ex-libris link opens in a sheet of its own, over a modal that covers the tabs.
enum LinkSheetContent: Equatable {
    /// The screen the link names, at the root of the sheet's own stack; pushed on `tab` when no
    /// sheet could be presented after all.
    case destination(NavigationDestination, tab: MainTabView.TabConfig)
    /// The Profil sheet, for a link to my own username.
    case profile
}
