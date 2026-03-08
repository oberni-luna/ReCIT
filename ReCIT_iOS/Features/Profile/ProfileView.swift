//
//  SettingsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import SwiftUI
import SwiftData
import LBSnackBar

struct ProfileView: View {
    @EnvironmentObject var authModel: AuthModel
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var transactionModel: TransactionModel
    @Environment(\.modelContext) var modelContext
    @Environment(\.snackBar) private var snackBar

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
            .navigationTitle("nav.profile")
        }
    }

    @ViewBuilder
    func connectedView(user: User) -> some View {
        List {
            Section {
                UserHeaderView(user: user)
            }

            Section {
                ForEach(transactions.sorted{ $0.lastActionDate > $1.lastActionDate } ) { transaction in
                    if transaction.isCurrent {
                        NavigationLink(
                            value: NavigationDestination.transaction(transaction: transaction)
                        ) {
                            TransactionCellView(transaction: transaction)
                        }
                    }
                }
            } header : {
                Text("profile.current_transactions")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }

            Section {
                ForEach(userModel.getAllOtherUsers(modelContext: modelContext).sorted(by: { $0.username < $1.username })) { otherUser in
                    NavigationLink(value: NavigationDestination.user(user: otherUser)) {
                        UserCellView(user: otherUser)
                    }
                }
            } header : {
                Text("profile.network")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }

            Section {
                AsyncButton(action: {
                    Task {
                        do {
                            try transactionModel.deleteLocalTransactions(modelContext: modelContext)
                            try userModel.logout(modelContext: modelContext)
                        } catch {
                            snackBar.show { SnackBarView.error(error) }
                        }
                        await authModel.logout()
                    }
                }, label: {
                    Text("profile.logout")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundError)
                })
            }
        }
    }

    @ViewBuilder
    var anonymousView: some View {
        Text("profile.anonymous")
    }
}
