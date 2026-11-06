//
//  UserTransactionsTabTitle.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftData
import SwiftUI

/// « Échanges • 5 »: every Échange between me and this reader, counted the way the Échanges tab
/// lists them, and a tinted dot after it while one of them waits to be read on my side — the dot
/// of its row in the tab.
struct UserTransactionsTabTitle: View {
    private static let dotSide: CGFloat = 8

    let user: User

    @Query private var transactions: [UserTransaction]

    @Environment(UserModel.self) private var userModel: UserModel

    var body: some View {
        let shared: TransactionSections = .init(transactions, with: user._id)
        HStack(spacing: .xSmall) {
            Text("user.tab.transactions \(shared.count)")
                .accessibilityLabel(Text("user.tab.transactions.accessibility \(shared.count)"))

            if shared.hasUnread(by: userModel.myUser?._id) {
                Circle()
                    .frame(width: Self.dotSide, height: Self.dotSide)
                    .foregroundStyle(.foregroundTinted)
                    .accessibilityLabel(Text("user.tab.transactions.unread"))
            }
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
    UserTransactionsTabTitle(user: camille)
        .textStyle(.action200)
        .environment(UserModel(apiService: APIService(env: .production)))
        .modelContainer(for: UserTransaction.self, inMemory: true)
}
