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
