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
    @Environment(SortFlowPresentation.self) private var sortFlow
    @Environment(UserModel.self) private var userModel
    @Environment(TransactionModel.self) private var transactionModel
    @Environment(AutoSortModel.self) private var autoSortModel
    @Environment(SyncStatusStore.self) private var syncStatus
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    @State private var path: NavigationPath = .init()
    @Query private var allTransactions: [UserTransaction]
    @Query(sort: \User.username) private var allUsers: [User]

    var currentTransactions: [UserTransaction] {
        allTransactions.filter(\.isCurrent)
    }

    /// Auto-sort's entry point here, derived on every render. Reading it inside the body
    /// is what keeps it live: the availability behind it reads an observable
    /// `SystemLanguageModel`, so switching Apple Intelligence on and coming back to the
    /// app reveals the row with no relaunch.
    private var autoSortEntryPoint: AutoSortEntryPoint {
        .init(availability: autoSortModel.availability)
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

            // Auto-sort's settings entry point. Since PRD 0008 it opens the sorting
            // surface, which is the app's only screen for creating étagères and filling
            // them — the review screen it used to open has been retired.
            //
            // The availability rule is kept, because this row is the offer of the
            // *automatic* rangement: on a device that cannot run Apple Intelligence it
            // would promise something the surface does not have, and the user can do
            // nothing about that, so an explanation here would be a nag rather than
            // information. Sorting by hand is not lost with it — the étagères screen's
            // own toolbar leads to the same surface on any device. See PRD 0006 / 0008.
            if autoSortEntryPoint.isVisible {
                Section {
                    if autoSortEntryPoint.isEnabled {
                        // A button rather than a link: the surface is a modal flow now, not a
                        // screen in this tab's stack (PRD 0009).
                        Button {
                            sortFlow.presentSorting()
                        } label: {
                            Text("profile.auto_sort")
                                .textStyle(.action300)
                                .foregroundStyle(.foregroundTinted)
                        }
                    } else {
                        // Named but inert, with the reason under it. A row that simply
                        // did nothing would read as a bug, and one that pushed into the
                        // flow would push into a wall.
                        Text("profile.auto_sort")
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundSecondary)
                        AutoSortUnavailableView(entryPoint: autoSortEntryPoint)
                    }
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

            // Scaffolding, and last on the screen so it reads as such. Both onboarding
            // screens are meant to be seen once, which leaves no way to look at them again
            // without one. Absent from Release builds — see `ProfileDebugSection`.
            #if DEBUG
            ProfileDebugSection(path: $path)
            #endif
        }
        .applyListBackground()
    }

    @ViewBuilder
    var anonymousView: some View {
        Text("profile.anonymous")
    }
}
