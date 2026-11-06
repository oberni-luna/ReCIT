//
//  UserTransactionsTab.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftData
import SwiftUI

/// The Échanges between me and a friend, under the Échanges tab of their profile: « En cours »,
/// then « Terminés », as « Toutes les transactions » splits them, whichever of us owns the copy.
/// Read from the store, which `TransactionModel.syncTransactions` fills with all of mine.
struct UserTransactionsTab: View {
    let user: User

    @Query private var transactions: [UserTransaction]

    var body: some View {
        let shared: TransactionsWithUser = .init(transactions, userId: user._id)
        if shared.isEmpty {
            Section {
                EmptyStateView(
                    glyph: "arrow.left.arrow.right",
                    title: "user.transactions.empty.title \(user.username)",
                    message: "user.transactions.empty.message"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, .large)
            }
            .listRowBackground(Color.clear)
        } else {
            UserTransactionsSection("user.transactions.current", transactions: shared.current)
            UserTransactionsSection("user.transactions.finished", transactions: shared.finished)
        }
    }
}

#Preview {
    let camille: User = .init(
        _id: "camille",
        _rev: "1",
        username: "Camille",
        email: nil,
        position: nil,
        avatarURLValue: nil,
        itemCount: 0
    )
    List {
        UserTransactionsTab(user: camille)
    }
    .modelContainer(for: UserTransaction.self, inMemory: true)
}
