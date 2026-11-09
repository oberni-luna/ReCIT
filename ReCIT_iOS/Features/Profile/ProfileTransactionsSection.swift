//
//  ProfileTransactionsSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 08/11/2026.
//

import SwiftData
import SwiftUI

/// The Profil's current Échanges, the latest first, and the way to all of them.
struct ProfileTransactionsSection: View {
    @Query private var allTransactions: [UserTransaction]

    @Environment(SyncStatusStore.self) private var syncStatus: SyncStatusStore

    private var currentTransactions: [UserTransaction] {
        allTransactions.filter(\.isCurrent)
    }

    var body: some View {
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
        } header: {
            Text("profile.current_transactions")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            ProfileTransactionsSection()
        }
    }
    .environment(SyncStatusStore())
    .environment(UserModel(apiService: APIService(env: .production)))
    .modelContainer(for: UserTransaction.self, inMemory: true)
}
