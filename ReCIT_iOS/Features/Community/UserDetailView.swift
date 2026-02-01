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
                VStack(alignment: .leading, spacing: .small) {
                    if let image = user.avatarURLValue {
                        CellThumbnail(imageUrl: image, cornerRadius: .full, size: 72)
                    }
                    Text(user.username)
                        .font(.headline)
                    Text("Item count \(user.itemCount)")
                        .font(.subheadline)
                }
            }

            Section {
                ForEach(user.items) { item in
                    Button {
                        path.append(NavigationDestination.item(item: item))
                    } label: {
                        InventoryCell(item: item)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Inventaire de \(user.username)")
            }
        }
        .navigationTitle("Utilisateur")
    }
}

#Preview {
//    UserDetailView()
}
