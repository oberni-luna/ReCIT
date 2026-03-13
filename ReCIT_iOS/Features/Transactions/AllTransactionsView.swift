//
//  AllTransactionsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import SwiftUI
import SwiftData

struct AllTransactionsView: View {
    @Query(sort: \UserTransaction.created, order: .reverse) private var allTransactions: [UserTransaction]

    private var currentTransactions: [UserTransaction] {
        allTransactions
            .filter(\.isCurrent)
            .sorted { $0.lastActionDate > $1.lastActionDate }
    }

    private var pastTransactions: [UserTransaction] {
        allTransactions
            .filter { !$0.isCurrent }
            .sorted { $0.lastActionDate > $1.lastActionDate }
    }

    var body: some View {
        List {
            if !currentTransactions.isEmpty {
                Section {
                    ForEach(currentTransactions) { transaction in
                        NavigationLink(value: NavigationDestination.transaction(transaction: transaction)) {
                            TransactionCellView(transaction: transaction)
                        }
                    }
                } header: {
                    Text("profile.current_transactions")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }

            if !pastTransactions.isEmpty {
                Section {
                    ForEach(pastTransactions) { transaction in
                        NavigationLink(value: NavigationDestination.transaction(transaction: transaction)) {
                            TransactionCellView(transaction: transaction)
                        }
                    }
                } header: {
                    Text("transactions.past")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
        }
        .navigationTitle("transactions.all")
    }
}
