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
        let shared: TransactionSections = .init(transactions, with: user._id)
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
            TransactionsSection("user.transactions.current", transactions: shared.current)
                .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
            TransactionsSection("user.transactions.finished", transactions: shared.finished)
                .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
        }
    }
}

private extension UserTransactionsTab {
    /// A store holding two ongoing Échanges with Camille and one that is over.
    struct PreviewStore: PreviewModifier {
        static func makeSharedContext() throws -> ModelContainer {
            let container: ModelContainer = try .init(
                for: UserTransaction.self,
                configurations: .init(isStoredInMemoryOnly: true)
            )
            let requested: UserTransaction = .mock(id: "requested")
            let transactions: [UserTransaction] = [
                requested,
                .mock(
                    id: "accepted",
                    item: requested.item,
                    owner: requested.owner,
                    requester: requested.requester,
                    state: .accepted
                ),
                .mock(
                    id: "returned",
                    item: requested.item,
                    owner: requested.owner,
                    requester: requested.requester,
                    state: .returned
                )
            ]
            for transaction in transactions {
                container.mainContext.insert(transaction)
            }
            return container
        }

        func body(
            content: Content,
            context: ModelContainer
        ) -> some View {
            content.modelContainer(context)
        }
    }
}

#Preview("En cours et Terminés", traits: .modifier(UserTransactionsTab.PreviewStore())) {
    List {
        UserTransactionsTab(user: UserTransaction.mock().owner)
    }
    .environment(UserModel(apiService: APIService(env: .production)))
}

#Preview("Aucun échange") {
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
