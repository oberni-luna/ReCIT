//
//  SettingsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var authModel: AuthModel
    @EnvironmentObject var userModel: UserModel
    @Environment(\.modelContext) var modelContext

    @State private var isOn: Bool = false
    @Query var users: [User]

    var body: some View {
        NavigationStack {
            Group {
                if authModel.isAuthenticated, let user = userModel.myUser {
                    connectedView(user: user)
                } else {
                    anonymousView
                }
            }
            .navigationTitle("Profile")
        }
    }

    @ViewBuilder
    func connectedView(user: User) -> some View {
        List {
            Section {
                UserCellView(user: user)
            }

            Section {
                Text("Transactions")

                Text("Friends")

                Text("Groups")
            }

            Section {
                AsyncButton(action: {
                    Task {
                        try? await userModel.logout(modelContext: modelContext)
                        await authModel.logout()
                    }
                }, label: {
                    Text("Se déconnecter")
                })
            }
        }
    }

    @ViewBuilder
    var anonymousView: some View {
        Text("Vous n'êtes pas connecté.")
    }
}
