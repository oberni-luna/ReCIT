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

    @State var path: NavigationPath = .init()
    @Query var users: [User]
    @Query(sort: \UserTransaction.created, order: .reverse) var transactions: [UserTransaction]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if authModel.isAuthenticated, let user = userModel.myUser {
                    connectedView(user: user)
                } else {
                    anonymousView
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationTitle("Profile")
        }
    }

    @ViewBuilder
    func connectedView(user: User) -> some View {
        List {
            Section {
                UserHeaderView(user: user)
            }

            Section("Transactions") {
                ForEach(transactions) { transaction in
                    NavigationLink(
                        value: NavigationDestination.transaction(transaction: transaction)
                    ) {
                        VStack(alignment: .leading, spacing: .xSmall) {
                            Text(transaction.item.edition?.title ?? "Unkown title")
                            Text("\(transaction.created.formatted()) : \(transaction.owner.username) → \(transaction.requester.username)")
                            Text(transaction.state.rawValue)
                        }
                    }
                }
            }

            Section("Network") {
                ForEach(userModel.getAllOtherUsers(modelContext: modelContext)) { otherUser in
                    NavigationLink(value: NavigationDestination.user(user: otherUser)) {
                        UserCellView(user: otherUser)
                    }
                }
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
