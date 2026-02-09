//
//  MyInventoryCell.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2025.
//

import SwiftUI

struct InventoryCell: View {
    let item: InventoryItem
    let filterParameter: InventoryItem.FilterParameter

    var body: some View {
        if let edition = item.edition {
            HStack(alignment: .top, spacing: .sMedium) {
                CellThumbnail(imageUrl: edition.image, cornerRadius: .minimal, size: 56)

                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(edition.title)
                        .font(.headline)

                    if let subtitle = edition.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                    }

                    Text(edition.authorNames.joined(separator: ", "))
                        .font(.caption)

                    HStack(alignment: .firstTextBaseline, spacing: .small) {
                        TransactionTypeLabel(transactionType: item.transaction)
                            .font(.caption)

                        if filterParameter == .othersInventory, let owner = item.owner {
                            Text(.init("Appartient à **\(owner.username)**"))
                                .font(.caption)
                                .foregroundStyle(.textDefault)
                        }
                    }

#if DEBUG
                    Text(edition.uri)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
#endif
                }
            }
        }
    }
}
