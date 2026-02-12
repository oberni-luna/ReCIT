//
//  UserItemCellView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/01/2026.
//

import SwiftUI

struct UserItemCellView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var inventoryModel: InventoryModel

    @Bindable var item: InventoryItem

    var body: some View {
        if let owner = item.owner {
            othersItemCellView(owner: owner)
        }
    }

    

    @ViewBuilder
    func othersItemCellView(owner: User) -> some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(alignment: .center, spacing: .small) {
                CellThumbnail(imageUrl: owner.avatarURLValue, cornerRadius: .full)
                VStack(alignment: .leading, spacing: .small) {
                    Text(owner.username)
                        .font(.headline)
                        .foregroundStyle(.textDefault)

                    HStack(alignment: .firstTextBaseline, spacing: .small) {
                        Text("Depuis \(item.created.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TransactionTypeLabel(transactionType: item.transaction)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(.chevronRight)
            }
            if !item.details.isEmpty {
                Text(item.details)
                    .font(.subheadline)
                    .foregroundStyle(.textDefault)
            }
        }
    }
}

