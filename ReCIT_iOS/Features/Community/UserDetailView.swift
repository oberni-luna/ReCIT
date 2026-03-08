//
//  UserDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/02/2026.
//

import SwiftUI

struct UserDetailView: View {
    @State private var nextNavigationDestination: NavigationDestination?

    let user: User
    @Binding var path: NavigationPath

    var body: some View {
        List {
            Section {
                UserHeaderView(user: user)
            }

            Section {
                ForEach(user.items) { item in
                    Button {
                        path.append(NavigationDestination.item(item: item))
                    } label: {
                        InventoryCell(item: item, filterParameter: .userInventory)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("user.inventory.header \(user.username)")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
        .navigationTitle("nav.user")
    }
}

#Preview {
//    UserDetailView()
}
