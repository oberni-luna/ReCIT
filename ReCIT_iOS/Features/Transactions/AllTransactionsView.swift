//
//  AllTransactionsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import SwiftUI
import SwiftData

struct AllTransactionsView: View {
    @Environment(SyncStatusStore.self) private var syncStatus
    @Query(sort: \UserTransaction.created, order: .reverse) private var allTransactions: [UserTransaction]

    var body: some View {
        if syncStatus.shouldShowPlaceholder(.transactions) {
            SyncingPlaceholderView()
                .navigationTitle("transactions.all")
        } else {
            let sections: TransactionSections = .init(allTransactions)
            List {
                Group {
                    TransactionsSection("profile.current_transactions", transactions: sections.current)
                    TransactionsSection("transactions.past", transactions: sections.finished)
                }
                .textCase(nil)
            }
            .applyListBackground()
            .navigationTitle("transactions.all")
        }
    }
}
