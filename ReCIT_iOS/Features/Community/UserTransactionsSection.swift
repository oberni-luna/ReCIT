//
//  UserTransactionsSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftData
import SwiftUI

/// « En cours » or « Terminés » under the Échanges tab of a friend's profile: the rows of
/// « Toutes les transactions », each opening its Échange. Nothing at all when it has none.
struct UserTransactionsSection: View {
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
            .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
        }
    }
}

private extension UserTransactionsSection {
    enum AccessibilityID {
        static let row: String = "e2e.user.transactionRow"
    }
}

#Preview {
    List {
        UserTransactionsSection("user.transactions.current", transactions: [])
    }
    .environment(UserModel(apiService: APIService(env: .production)))
    .modelContainer(for: UserTransaction.self, inMemory: true)
}
