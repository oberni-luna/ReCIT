//
//  InventoryItemDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//
import SwiftData
import SwiftUI

struct InventoryItemDetailView: View {
    @EnvironmentObject var listModel: ListModel
    @Query(sort: \EntityList.name) var entityLists: [EntityList]

    let item: InventoryItem

    var body: some View {
        itemContentView
    }

    @ViewBuilder
    var itemContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .medium) {
                if let edition = item.edition {
                    EditionHeaderView(edition: edition)
                }
                if let owner = item.owner {
                    UserCellView(user: owner, description: "Owner")
                }
                
            }
            .padding(.horizontal, .medium)
        }
    }

    @ViewBuilder
    var addToListButton: some View {
        if let invEntity = item.edition {
            Menu("Add to a list") {
                ForEach(entityLists) { entityList in
                    Button(entityList.name) {
                        Task {
                            try await listModel.addEntitiesToList(listId: entityList._id, entityUris: [invEntity.uri])
                        }
                    }
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

