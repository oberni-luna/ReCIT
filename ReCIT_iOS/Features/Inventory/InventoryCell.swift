//
//  MyInventoryCell.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2025.
//

import SwiftUI

struct InventoryCell: View {
    let item: InventoryItem

    var body: some View {
        if let edition = item.edition {
            HStack(spacing: .small) {
                EditionImage(imageUrl: edition.image, contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: .medium))

                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(edition.title)
                        .font(.headline)

                    if let subtitle = edition.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                    }

                    Text(edition.authors.joined(separator: ", "))
                        .font(.caption)

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
