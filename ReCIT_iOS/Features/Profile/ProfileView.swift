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
    @Environment(AuthModel.self) private var authModel
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
    ///
    /// `relation == .friend`, not "every user that is not me": the store also holds the
    /// owners met in a transaction and the readers looked up in the search, and this section
    /// called all of them my network until issue 0083.
    var otherUsers: [User] {
        allUsers.filter { $0._id != userModel.myUser?._id && $0.relation == .friend }
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
                } else {
                    if otherUsers.isEmpty {
                        Text("profile.network.empty")
                    } else {
                        ForEach(otherUsers) { otherUser in
                            NavigationLink(value: NavigationDestination.user(user: otherUser)) {
                                UserCellView(user: otherUser)
                            }
                        }
                    }

                    // The way in, and the only one: the network is otherwise built on the
                    // website. Kept below the friends and present even when there are none —
                    // an empty network is exactly when one needs it.
                    NavigationLink(value: NavigationDestination.addFriends) {
                        Text("network.add_friends")
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundTinted)
                    }
                    .accessibilityIdentifier("e2e.profile.addFriends")
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
                    action: { await signOut() },
                    actionOptions: [.showProgressView],
                    label: {
                        Text("profile.logout")
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundError)
                    }
                )
                .accessibilityIdentifier("e2e.profile.logout")
            }

            // Its own section, below signing out and away from it: one row ends a session, the
            // other ends an account, and they should not be two adjacent red lines under the
            // same thumb. Last of the real screen, which is where a door of this kind belongs —
            // and where Apple expects to find it (App Review 5.1.1(v): an app that creates
            // accounts must let them be deleted from inside the app).
            Section {
                NavigationLink(value: NavigationDestination.deleteAccount) {
                    Text("profile.delete_account")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundError)
                }
                .accessibilityIdentifier("e2e.profile.deleteAccount")
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

    /// What this tab shows when there is no user to show: the statement, and a way out of it.
    ///
    /// Reachable in two ways, and the button answers both. Signed out, it is what the screen
    /// says while `RootView` is about to replace the whole tab view with the authentication
    /// flow. Signed in but with no user — a session the server has stopped honouring — it is the
    /// only screen that tells the truth, and before issue 0068 it was also a dead end: the tabs
    /// stayed up, every call failed, and the placeholders spun for ever with nothing to tap.
    @ViewBuilder
    var anonymousView: some View {
        VStack(spacing: .medium) {
            Text("profile.anonymous")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)

            // Signing out *is* the way to the sign-in flow: `RootView` shows the authentication
            // flow exactly when `isAuthenticated` is false, so what this button has to do is
            // drop the session the app is holding — which is also the stale one that got the
            // user here. Same action as the row above, on purpose.
            AsyncButton(
                action: { await signOut() },
                actionOptions: [.showProgressView],
                label: {
                    Text("login.button.signin")
                }
            )
            .buttonStyle(.primary())
            .accessibilityIdentifier("e2e.profile.signin")
        }
        .padding(.all, .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyListBackground()
    }

    /// Drops the session and everything local that belonged to it.
    ///
    /// One method for the two buttons that need it: the sign-out row, and the sign-in button on
    /// `anonymousView` — which reaches the login flow *through* a sign-out, since a session the
    /// server no longer honours has to go before a new one can be opened.
    private func signOut() async {
        await authModel.logout()
        await Task.yield()
        do {
            try transactionModel.deleteLocalTransactions(modelContext: modelContext)
            try userModel.logout(modelContext: modelContext)
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}
