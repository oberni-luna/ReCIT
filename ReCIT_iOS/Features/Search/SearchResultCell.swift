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
        switch result.type {
        case .humans:
            authorCell
        case .inventoryItem:
            inventoryItemCell
        default:
            workCell
        }
    }

    @ViewBuilder
    var workCell: some View {
        HStack(alignment: .top, spacing: 12) {
            CellThumbnail(imageUrl: result.imageUrl)

            textsCell
        }
    }

    @ViewBuilder
    var authorCell: some View {
        HStack(alignment: .top, spacing: 12) {
            CellThumbnail(imageUrl: result.imageUrl, cornerRadius: .full)

            textsCell
        }
    }

    @ViewBuilder
    var inventoryItemCell: some View {
        HStack(alignment: .top, spacing: 12) {
            CellThumbnail(imageUrl: result.imageUrl)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)

                if let description = result.description, !description.isEmpty {
                    Text(description)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }

                if let localItem = result.localItem {
                    Text("inventory.owned_by \(localItem.owner?.username ?? "someone, somewhere")")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
        }
    }

    @ViewBuilder
    var textsCell: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.title)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)

            if let description = result.description, !description.isEmpty {
                Text(description)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }
}
