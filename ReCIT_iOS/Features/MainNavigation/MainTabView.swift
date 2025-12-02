//
//  MainTabView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/08/2025.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    let authModel: AuthModel
    
    enum TabConfig: String, Hashable, CaseIterable {
        case community
        case inventory
        case transactions
        case settings

        // Use for dev in order to hide tab on progress for exemple
        var isHidden: Bool {
            switch self {
            case .community:
                true
            case .inventory:
                false
            case .transactions:
                false
            case .settings:
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
            }
        }
    }

    @State var selectedTab: TabConfig = .community

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabConfig.allCases, id: \.self) { tabConfig in

                let symbolVariant: SymbolVariants = (selectedTab == tabConfig ? .fill : .none)

                Tab(value: tabConfig) {
                    view(for: tabConfig)
                        .navigationTitle(tabConfig.title)
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

// MARK: Subviews
private extension MainTabView {
    @ViewBuilder
    func view(for tab: TabConfig) -> some View {
        switch tab {
        case .community:
            EntityListView()
        case .inventory:
            InventoryView()
        case .transactions:
            Text("Transactions View")
                .navigationTitle("Transactions")
                .navigationBarTitleDisplayMode(.inline)
        case .settings:
            ProfileView(authModel: authModel)
                .navigationTitle("Réglages")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
