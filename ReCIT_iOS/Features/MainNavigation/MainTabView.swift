//
//  MainTabView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/08/2025.
//

import Foundation
import SwiftUI
import LBSnackBar

struct MainTabView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.snackBar) private var snackBar
    @Environment(SortFlowPresentation.self) private var sortFlow
    let authModel: AuthModel
    
    enum TabConfig: String, Hashable, CaseIterable {
        case community
        case inventory
        case transactions
        case lists
        case profile
        case search

        // Use for dev in order to hide tab on progress for exemple
        var isHidden: Bool {
            switch self {
            case .community:
                true
            case .inventory:
                false
            case .transactions:
                true
            case .profile:
                false
            case .lists:
                false
            case .search:
                false
            }
        }

        var systemIcon: String {
            switch self {
            case .community:
                "person.3"
            case .inventory:
                "book"
            case .transactions:
                "arrow.left.arrow.right"
            case .profile:
                "person"
            case .lists:
                "list.bullet"
            case .search:
                "magnifyingglass"
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
            case .search:
                String(localized: "tab.search")
            }
        }

        var role: TabRole? {
            switch self {
            case .search:
                return .search
            default:
                return .none
            }
        }
    }

    @State var selectedTab: TabConfig = .community
    /// The book being pressed on the bookshelf, if any. Owned here because the focus overlay
    /// it drives has to reach over the nav bar and the tab bar. See ADR 0006.
    @State private var shelfFocus: ShelfFocusModel = .init()

    /// The flow's flag as a binding. `@Environment` hands over an observable, not a binding,
    /// and a cover needs one.
    private var presentsSortFlow: Binding<Bool> {
        .init(
            get: { sortFlow.isPresented },
            set: { sortFlow.isPresented = $0 }
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabConfig.allCases, id: \.self) { tabConfig in
                if !tabConfig.isHidden {
                    let symbolVariant: SymbolVariants = (selectedTab == tabConfig ? .fill : .none)

                    Tab(value: tabConfig, role: tabConfig.role) {
                        view(for: tabConfig)
                    } label: {
                        Label {
                            Text(tabConfig.title)
                        } icon: {
                            Image(systemName: tabConfig.systemIcon)
                        }
                        .environment(\.symbolVariants, symbolVariant)
                    }
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
        // The sorting flow, over the built app rather than inside a tab: it is a modal flow
        // (PRD 0009), and presenting it from each of its four entry points would mean the same
        // screen presented from two tabs at once.
        .fullScreenCover(isPresented: presentsSortFlow) {
            SortFlowView(start: .sorting)
        }
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
            CommunityView()
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
        case .search:
            AddInventoryItemSearchView()
                .navigationTitle("nav.search")
        }
    }
}
