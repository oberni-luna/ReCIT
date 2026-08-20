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
    @EnvironmentObject private var authModel: AuthModel
    @Environment(UserModel.self) private var userModel
    @Environment(TransactionModel.self) private var transactionModel
    @Environment(SyncStatusStore.self) private var syncStatus
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    @State private var path: NavigationPath = .init()
    @Query private var allTransactions: [UserTransaction]
    @Query(sort: \User.username) private var allUsers: [User]

    var currentTransactions: [UserTransaction] {
        allTransactions.filter(\.isCurrent)
    }

    /// Friends, sourced reactively from SwiftData (excludes the logged-in user).
    var otherUsers: [User] {
        allUsers.filter { $0._id != userModel.myUser?._id }
    }

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
                if syncStatus.shouldShowPlaceholder(.transactions) {
                    SyncingInlineRow()
                } else {
                    if !currentTransactions.isEmpty {
                        ForEach(currentTransactions.sorted { $0.lastActionDate > $1.lastActionDate }) { transaction in
                            NavigationLink(
                                value: NavigationDestination.transaction(transaction: transaction)
                            ) {
                                TransactionCellView(transaction: transaction)
                            }
                        }
                    } else {
                        Text("profile.current_transactions.empty")
                    }

                    NavigationLink(value: NavigationDestination.allTransactions) {
                        Text("transactions.see_all")
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundTinted)
                    }
                }
            } header : {
                Text("profile.current_transactions")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }

            Section {
                if syncStatus.shouldShowPlaceholder(.community) {
                    SyncingInlineRow()
                } else if otherUsers.isEmpty {
                    Text("profile.network.empty")
                } else {
                    ForEach(otherUsers) { otherUser in
                        NavigationLink(value: NavigationDestination.user(user: otherUser)) {
                            UserCellView(user: otherUser)
                        }
                    }
                }
            } header : {
                Text("profile.network")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }

            // The only route to auto-sort for a user who already has étagères — the
            // empty-shelf card is by definition not shown to them. The empty-state
            // entry point and the differentiated availability copy are issue 0025;
            // this entry is deliberately plain. See PRD 0006.
            Section {
                NavigationLink(value: NavigationDestination.autoSort) {
                    Text("profile.auto_sort")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundTinted)
                }
            }

            Section {
                AsyncButton(
                    action: {
                        await authModel.logout()
                        await Task.yield()
                        do {
                            try transactionModel.deleteLocalTransactions(modelContext: modelContext)
                            try userModel.logout(modelContext: modelContext)
                        } catch {
                            snackBar.show { SnackBarView.error(error) }
                        }
                    },
                    actionOptions: [.showProgressView],
                    label: {
                        Text("profile.logout")
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundError)
                    }
                )
            }
        }
        .applyListBackground()
    }

    @ViewBuilder
    var anonymousView: some View {
        Text("profile.anonymous")
    }
}
