//
//  MainTabView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/08/2025.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var userModel: UserModel
    let authModel: AuthModel
    
    enum TabConfig: String, Hashable, CaseIterable {
        case community
        case inventory
        case transactions
        case lists
        case settings
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
            case .settings:
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
            case .settings:
                "gearshape"
            case .lists:
                "list.bullet"
            case .search:
                "magnifyingglass"
            }
        }

        var title: String {
            switch self {
            case .community:
                "Community"
            case .inventory:
                "Inventory"
            case .transactions:
                "Transactions"
            case .settings:
                "Settings"
            case .lists:
                "Lists"
            case .search:
                "Search"
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
            if let user = userModel.myUser {
                InventoryView(user: user)
            } else {
                EmptyView()
            }
        case .transactions:
            Text("Transactions View")
                .navigationTitle("Transactions")
                .navigationBarTitleDisplayMode(.inline)
        case .settings:
            ProfileView()
                .navigationTitle("Réglages")
                .navigationBarTitleDisplayMode(.inline)
        case .lists:
            EntityListView()
                .navigationTitle("Listes")
        case .search:
            AddInventoryItemSearchView()
                .navigationTitle("Search")
        }
    }
}
