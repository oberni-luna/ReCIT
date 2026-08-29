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
        // `isStillInTheStore` first, and it is not decoration: this cell is the one the crash of
        // issue 0065 came out of. The book screen deletes the copy and stays put, this row is
        // still on screen behind it, and the deletion invalidates its body — which then read
        // `item.transaction` off a model with no row left and trapped. See
        // `PersistentModel+StillInTheStore`.
        if item.isStillInTheStore, let edition = item.edition {
            HStack(alignment: .top, spacing: .sMedium) {
                CellThumbnail(imageUrl: edition.image, cornerRadius: .minimal, size: .medium)

                VStack(alignment: .leading, spacing: .xSmall) {
                    Group {
                        Text(edition.title)
                            .textStyle(.content400Bold)

                        if let subtitle = edition.subtitle {
                            Text(subtitle)
                                .textStyle(.content300)
                        }

                        Text(edition.authorNames.joined(separator: ", "))
                            .textStyle(.footnote200)

                    }
                    .foregroundStyle(.foregroundDefault)
                    
                    HStack(alignment: .firstTextBaseline, spacing: .small) {
                        item.transaction.label
                            .labelStyle(.tag)

                        if filterParameter == .othersInventory, let owner = item.owner {
                            Text(.init(String(localized: "inventory.owned_by \(owner.username)")))
                                .textStyle(.footnote200Bold)
                                .foregroundStyle(.foregroundDefault)
                        }
                    }
                }
            }
        }
    }
}
