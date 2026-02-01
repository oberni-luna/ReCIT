//
//  UserCellView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/01/2026.
//

import SwiftUI

struct UserItemCellView: View {
    let item: InventoryItem

    var body: some View {
        if let owner = item.owner {
            Group {
                HStack(alignment: .center, spacing: .small) {
                    CellThumbnail(imageUrl: owner.avatarURLValue, cornerRadius: .full)
                    VStack(alignment: .leading, spacing: .small) {
                        Text(owner.username)
                            .font(.headline)
                            .foregroundStyle(.textDefault)

                        Text("Depuis \(item.created.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(.chevronRight)
                }

                if let details = item.details, !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                }
            }
        }
    }
}

