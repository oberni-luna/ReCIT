//
//  DeleteAccountView.swift
//  ReCIT_iOS
//
//  The screen between the Profil's last row and an account that no longer exists.
//
//  Two gestures rather than one, on purpose. A single destructive alert on a list row is one
//  slipped finger away from erasing a whole library, so the row opens *this* — which says what
//  will be lost, counted — and only the button at its foot raises the alert that acts. What the
//  screen counts is what the server destroys (`AccountDeletionSummary`), not a prettier
//  approximation of it.
//
//  Nothing local is touched before the server has said `ok`: see `UserModel.deleteAccount`. A
//  failure leaves the screen up with its button live and the reason in a SnackBar — the user is
//  standing right here, so the error belongs on this screen rather than in the app-wide reporter
//  that `MainTabView` observes for background work.
//

import SwiftUI
import SwiftData
import LBSnackBar

struct DeleteAccountView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(AuthModel.self) private var authModel
    @Environment(OnboardingStore.self) private var onboardingStore
    @Environment(TipsStore.self) private var tipsStore
    @Environment(RecentSearchStore.self) private var recentSearchStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    @Query private var items: [InventoryItem]
    @Query private var shelves: [Shelf]
    @Query private var lists: [EntityList]
    @Query private var transactions: [UserTransaction]

    @State private var isConfirming: Bool = false

    /// What this account stands to lose, from the local copy.
    ///
    /// Items and étagères are filtered to the signed-in user because the store also holds
    /// friends' — the server only deletes this user's, and promising to delete someone else's
    /// would be both false and alarming. Lists are all mine: only mine are ever synced.
    private var summary: AccountDeletionSummary {
        let myId: String = userModel.myUser?._id ?? ""
        return .init(
            books: items.count(where: { $0.ownerId == myId }),
            shelves: shelves.count(where: { $0.ownerId == myId }),
            lists: lists.count,
            activeTransactions: transactions.count(where: \.isCurrent)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .large) {
                Text("delete_account.intro")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                if summary.isEmpty {
                    Text("delete_account.empty")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                } else {
                    AccountDeletionLinesView(summary: summary)
                }

                if summary.warnsAboutActiveTransactions {
                    Text("delete_account.transactions_warning")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundError)
                }

                VStack(alignment: .leading, spacing: .small) {
                    Text("delete_account.hosting")
                    Text("delete_account.username_kept")
                }
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)

                Button("delete_account.button", role: .destructive) {
                    isConfirming = true
                }
                .buttonStyle(.destructive())
                .accessibilityIdentifier("e2e.deleteAccount.confirm")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.all, .large)
        }
        .applyListBackground()
        .navigationTitle("delete_account.title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("delete_account.confirm.title", isPresented: $isConfirming) {
            Button("action.cancel", role: .cancel) {}
            Button("delete_account.confirm.delete", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("delete_account.confirm.message")
        }
    }

    /// Deletes the account, then leaves the phone with nothing of it.
    ///
    /// The order is the whole method. The user id is read *before* the call, because the model
    /// drops `myUser` on success and the three per-account stores are keyed by that id. The
    /// session is forgotten *last*: it flips `isAuthenticated`, and `RootView` swaps this whole
    /// tab view for the welcome screen the moment it does — anything left after it would run on
    /// a screen already gone.
    private func deleteAccount() async {
        guard let userId: String = userModel.myUser?._id else { return }

        do {
            try await userModel.deleteAccount(modelContext: modelContext)
            recentSearchStore.clear(userId: userId)
            onboardingStore.resetWelcome(userId: userId)
            tipsStore.resetTips(userId: userId)
            authModel.forgetSession()
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}

/// The counted lines, one per thing there is something of.
private struct AccountDeletionLinesView: View {
    let summary: AccountDeletionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            ForEach(summary.lines) { line in
                Text(text(for: line))
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
            }
        }
    }

    private func text(for line: AccountDeletionSummary.Line) -> LocalizedStringKey {
        switch line.kind {
        case .books: "delete_account.line.books \(line.count)"
        case .shelves: "delete_account.line.shelves \(line.count)"
        case .lists: "delete_account.line.lists \(line.count)"
        case .activeTransactions: "delete_account.line.transactions \(line.count)"
        }
    }
}
