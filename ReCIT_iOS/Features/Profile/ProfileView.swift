//
//  SettingsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AuthModel.self) private var authModel
    @Environment(UserModel.self) private var userModel
    @Environment(SyncStatusStore.self) private var syncStatus

    @State private var path: NavigationPath = .init()
    @Query private var allTransactions: [UserTransaction]
    /// Whether the inventaire.io tag has been put away. Kept on the device, not on the account:
    /// it speaks of the app, so signing out and in again does not bring it back.
    @AppStorage("profile.inventaireNotice.dismissed") private var isInventaireNoticeDismissed: Bool = false

    var currentTransactions: [UserTransaction] {
        allTransactions.filter(\.isCurrent)
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

            // Right under the account: the one place the app says out loud that it is
            // inventaire.io underneath. See feature 0026. The invitations that used to sit above
            // it moved to the Réseau tab with the rest of the network (PRD 0016).
            if isInventaireNoticeDismissed == false {
                Section {
                    InventaireNoticeTag {
                        withAnimation {
                            isInventaireNoticeDismissed = true
                        }
                    }
                    // Inset on every side: the section clips its row to rounded corners, which
                    // would otherwise cut the leaning paper's corners and its shadow.
                    .listRowInsets(top: .small, leading: .small, bottom: .small, trailing: .small)
                    .listRowBackground(Color.clear)
                }
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

    /// Drops the session.
    ///
    /// One method for the two buttons that need it: the sign-out row, and the sign-in button on
    /// `anonymousView` — which reaches the login flow *through* a sign-out, since a session the
    /// server no longer honours has to go before a new one can be opened.
    ///
    /// Nothing local is deleted here: `RootView` does it for every way a session ends, this one
    /// included — see `RootView.forgetSignedOutUser()`.
    private func signOut() async {
        await authModel.logout()
    }
}
