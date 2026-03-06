//
//  WorkHeaderView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import SwiftUI
import SwiftData

struct EntityHeaderView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext

    let title: String
    let subtitle: String?
    let imageUrl: String?

    var body: some View {
        EntityImageView(imageUrl: imageUrl) {
            VStack(alignment: .leading, spacing: .small) {
                Text(title)
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundDefault)

                if let subtitle {
                    Text(subtitle)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
        }
    }
}
