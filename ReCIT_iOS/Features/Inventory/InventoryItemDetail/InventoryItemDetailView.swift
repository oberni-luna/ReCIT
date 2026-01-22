//
//  InventoryItemDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//
import SwiftData
import SwiftUI

struct InventoryItemDetailView: View {
    @EnvironmentObject var inventoryModel: InventoryModel
    @EnvironmentObject var listModel: ListModel
    @Query(sort: \EntityList.name) var entityLists: [EntityList]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false
    @State private var browseEntityDestination: EntityDestination?

    let item: InventoryItem

    var body: some View {
        itemContentView
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
            }
            .confirmationDialog("Supprimer cet item de votre inventaire ?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    Task {
                        try? await inventoryModel.removeItem(item, modelContext: modelContext)
                    }
                    dismiss()
                }
                Button("Annuler", role: .cancel) { }
            }
            .sheet(item: $browseEntityDestination) { destination in
                EntityBrowserView(startingPoint: destination)
            }
    }

    @ViewBuilder
    var itemContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .medium) {
                if let edition = item.edition {
                    EditionHeaderView(edition: edition)
                        .padding(.horizontal, .medium)
                }
                if let owner = item.owner {
                    UserCellView(user: owner, description: "Owner")
                        .padding(.horizontal, .medium)
                }

                if let edition = item.edition {
                    ScrollView(.horizontal) {
                        HStack(spacing: .small) {
                            ForEach(edition.works) { work in
                                Button {
                                    browseEntityDestination = .work(uri: work.uri)
                                } label: {
                                    Text(work.title)
                                }
                                .frame(maxWidth: 150)
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal, .medium)
                    }
                }
            }
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

