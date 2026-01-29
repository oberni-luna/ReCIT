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
    @Binding var path: NavigationPath

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
            .onChange(of: browseEntityDestination) { _, destination in
                if let destination {
                    path.append(destination)
                    browseEntityDestination = nil
                }
            }
    }

    @ViewBuilder
    var itemContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .medium) {
                if let edition = item.edition {
                    EditionHeaderView(
                        edition: edition
                    )
                    .padding(.horizontal, .medium)

                    EditionAuthorsView(
                        edition: edition,
                        entityDestination: $browseEntityDestination
                    )

                    EntitySummaryView(
                        entityUri: edition.uri,
                        otherEntityUri: edition.works.count == 1 ? edition.works.first?.uri : nil
                    )
                    .padding(.horizontal, .medium)
                }
                if let owner = item.owner {
                    UserCellView(user: owner, description: "Owner")
                        .padding(.horizontal, .medium)
                }

                if let details = item.details, !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .padding(.horizontal, .medium)
                }

                if let edition = item.edition {
                    VStack(spacing: .small) {
                        ForEach(edition.works) { work in
                            Button {
                                browseEntityDestination = EntityDestination.work(uri: work.uri)
                            } label: {
                                Text("Other edition for \(work.title)")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, .medium)
                }
            }
        }
        .navigationTitle("Livre")
        .navigationBarTitleDisplayMode(.inline)
    }
}

