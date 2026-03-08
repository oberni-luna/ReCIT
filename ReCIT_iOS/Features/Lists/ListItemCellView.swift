//
//  EditionCellView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 29/01/2026.
//

import SwiftUI
import SwiftData

struct ListItemCellView: View {
    let listItem: EntityListItem
    let entity: any Entity

    var body: some View {
        switch entity.self {
        case is Author:
            authorCell
        default:
            workCell
        }
    }

    @ViewBuilder
    var workCell: some View {
        HStack(alignment: .top, spacing: 12) {
            CellThumbnail(imageUrl: entity.image)

            textsCell
        }
    }

    @ViewBuilder
    var authorCell: some View {
        HStack(alignment: .top, spacing: 12) {
            CellThumbnail(imageUrl: entity.image, cornerRadius: .full)

            textsCell
        }
    }

    @ViewBuilder
    var textsCell: some View {
        VStack(alignment: .leading, spacing: 4) {

            if !listItem.comment.isEmpty {
                Text(listItem.comment)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
            }

            Text(entity.title)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)

            if let description = entity.subtitle, !description.isEmpty {
                Text(description)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }
}

