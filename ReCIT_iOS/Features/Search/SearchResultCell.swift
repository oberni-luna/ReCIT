//
//  SearchResultCell.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//

import SwiftUI

struct SearchResultCell: View {
    let result: SearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CellThumbnail(imageUrl: result.imageUrl)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                if let description = result.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
