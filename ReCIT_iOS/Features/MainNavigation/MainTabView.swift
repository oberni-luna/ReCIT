//
//  MainTabView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/08/2025.
//

import Foundation
import SwiftUI
import SwiftData
import LBSnackBar

struct MainTabView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.snackBar) private var snackBar
    let authModel: AuthModel
    
    /// In the tab bar's order: `CaseIterable` is what lays the tabs out.
    enum TabConfig: String, Hashable, CaseIterable {
        case inventory
        case lists
        /// The Réseau tab — friends and groups. Hidden until PRD 0016, when the network left the
        /// Profil for a tab of its own.
        case community
        case transactions
        case profile

        // Use for dev in order to hide tab on progress for exemple
        var isHidden: Bool {
            switch self {
            case .community:
                false
            case .inventory:
                false
            case .transactions:
                true
            case .profile:
                false
            case .lists:
                false
            }
        }

        var systemIcon: String {
            switch self {
            case .community:
                "person.2"
            case .inventory:
                "book"
            case .transactions:
                "arrow.left.arrow.right"
            case .profile:
                "person"
            case .lists:
                "list.clipboard"
            }
        }

        var title: String {
            switch self {
            case .community:
                String(localized: "tab.community")
            case .inventory:
                String(localized: "tab.inventory")
            case .transactions:
                String(localized: "tab.transactions")
            case .profile:
                String(localized: "tab.profile")
            case .lists:
                String(localized: "tab.lists")
            }
        }
    }

    @State var selectedTab: TabConfig = .inventory
    /// The book being pressed on the bookshelf, if any. Owned here because the focus overlay
    /// it drives has to reach over the nav bar and the tab bar. See ADR 0006.
    @State private var shelfFocus: ShelfFocusModel = .init()
    @Query private var allUsers: [User]

    /// What the Réseau tab's badge counts: everything there that waits on an answer from me.
    /// inventaire.io notifies nobody, so without it an invitation is only found by chance.
    private var networkBadgeCount: Int {
        allUsers.filter { $0.relation == .requestReceived }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabConfig.allCases, id: \.self) { tabConfig in
                if !tabConfig.isHidden {
                    let symbolVariant: SymbolVariants = (selectedTab == tabConfig ? .fill : .none)

                    Tab(value: tabConfig) {
                        view(for: tabConfig)
                    } label: {
                        Label {
                            Text(tabConfig.title)
                        } icon: {
                            Image(systemName: tabConfig.systemIcon)
                        }
                        .environment(\.symbolVariants, symbolVariant)
                    }
                    .badge(tabConfig == .community ? networkBadgeCount : 0)
                }
            }
        }
        .environment(shelfFocus)
        .overlay {
            if shelfFocus.isPressing {
                ShelfFocusOverlayView(focus: shelfFocus)
            }
        }
        // The first-launch accueil, over the built app rather than instead of it: the
        // composition root would have to choose before the user is known. See PRD 0007.
        .onboardingWelcome(user: userModel.myUser)
        .onChange(of: errorReporter.lastFailure?.id) { _, _ in
            if let failure = errorReporter.lastFailure {
                snackBar.show { SnackBarView.error(failure.error) }
            }
        }
    }
}

// MARK: Subviews
private extension MainTabView {
    @ViewBuilder
    func view(for tab: TabConfig) -> some View {
        switch tab {
        case .community:
            NetworkView()
        case .inventory:
            ShelvesView()
        case .transactions:
            Text("nav.transactions_placeholder")
                .navigationTitle("nav.transactions")
                .navigationBarTitleDisplayMode(.inline)
        case .profile:
            ProfileView()
                .navigationTitle("nav.settings")
                .navigationBarTitleDisplayMode(.inline)
        case .lists:
            EntityListView()
                .navigationTitle("nav.lists")
        }
    }
}
