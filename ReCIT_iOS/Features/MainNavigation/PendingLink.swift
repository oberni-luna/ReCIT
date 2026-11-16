//
//  PendingLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

/// The screen an Ex-libris link asked for, and the tab whose stack pushes it: books and authors on
/// Recherche, readers and groups on Réseau, lists on Listes. Held by `TabRouter` until that tab's root
/// takes it.
struct PendingLink: Equatable {
    let destination: NavigationDestination
    let tab: MainTabView.TabConfig
}
