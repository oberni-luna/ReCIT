//
//  EditionCellView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 29/01/2026.
//

import SwiftUI
import SwiftData

struct EntityCellView: View {
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
            Text(entity.title)
                .font(.headline)
            if let description = entity.subtitle, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

