//
//  TransactionsSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftData
import SwiftUI

/// A section of Échanges under its header, each row opening its Échange — on « Toutes les
/// transactions » and on a friend's Échanges tab. Nothing at all when it has none.
struct TransactionsSection: View {
    private let title: LocalizedStringKey
    private let transactions: [UserTransaction]

    init(_ title: LocalizedStringKey, transactions: [UserTransaction]) {
        self.title = title
        self.transactions = transactions
    }

    var body: some View {
        if transactions.isEmpty == false {
            Section {
                ForEach(transactions) { transaction in
                    NavigationLink(value: NavigationDestination.transaction(transaction: transaction)) {
                        TransactionCellView(transaction: transaction)
                    }
                    .accessibilityIdentifier(AccessibilityID.row)
                }
            } header: {
                Text(title)
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }
}

private extension TransactionsSection {
    enum AccessibilityID {
        static let row: String = "e2e.transactions.row"
    }
}

#Preview {
    List {
        TransactionsSection(
            "profile.current_transactions",
            transactions: [
                .mock(id: "requested"),
                .mock(id: "accepted", state: .accepted)
            ]
        )
    }
    .environment(UserModel(apiService: APIService(env: .production)))
    .modelContainer(for: UserTransaction.self, inMemory: true)
}
