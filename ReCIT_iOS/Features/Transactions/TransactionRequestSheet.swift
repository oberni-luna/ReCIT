//
//  TransactionRequestSheet.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import SwiftData
import SwiftUI

/// The sheet asking a friend for their copy of a book: an Échange not sent yet, in the form that
/// writes its first message.
struct TransactionRequestSheet: View {
    private let item: InventoryItem

    @Environment(UserModel.self) private var userModel: UserModel

    init(_ item: InventoryItem) {
        self.item = item
    }

    var body: some View {
        if let owner = item.owner, let requester = userModel.myUser {
            TransactionFormView(
                transaction: .init(
                    _id: "",
                    _rev: "",
                    item: item,
                    owner: owner,
                    requester: requester,
                    type: item.transaction,
                    created: .now,
                    messages: [],
                    state: .requested,
                    actions: [],
                    readStatus: .init(owner: false, requester: true)
                ),
                transition: TransactionStateMachine.requestTransition
            )
        }
    }
}

#Preview(traits: .modifier(FriendItemsPreviewStore())) {
    @Previewable @Environment(UserModel.self) var userModel: UserModel
    @Previewable @Query var items: [InventoryItem]

    if let item = items.first(where: { $0.ownerId != userModel.myUser?._id }) {
        TransactionRequestSheet(item)
    }
}
