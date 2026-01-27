//
//  WorkHeaderView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import SwiftUI
import SwiftData

struct WorkHeaderView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @EnvironmentObject var listModel: ListModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \EntityList.name) var entityLists: [EntityList]
    let work: Work

    var body: some View {
        EntityHeaderView(imageUrl: work.image) {
            VStack(alignment: .leading, spacing: .small) {
                Text(work.title)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.textDefault)

                if let subtitle = work.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
                
                addToListButton
            }
        }
    }

    @ViewBuilder
    var addToListButton: some View {
        Menu("Add to a list") {
            ForEach(entityLists) { entityList in
                Button(entityList.name) {
                    Task {
                        try await listModel.addEntitiesToList(listId: entityList._id, entityUris: [work.uri])
                    }
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
