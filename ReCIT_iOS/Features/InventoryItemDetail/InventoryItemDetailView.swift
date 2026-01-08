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
            VStack(alignment: .leading, spacing: .xSmall) {
                if let invEntity = item.edition {
                    EditionImage(imageUrl: invEntity.image, contentMode: .fit)
                        .frame(maxHeight: 256)
                        .clipped()

                    Text(invEntity.title)
                        .font(.largeTitle)
                        .bold()
                    if let subtitle = invEntity.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                    }
                    
                    Text(.init(invEntity.works.map { "**\($0.title)** : \($0.authors.map {$0.name}.joined(separator: ","))" }.joined(separator: "\n")))
                }
            }
            .padding()
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

