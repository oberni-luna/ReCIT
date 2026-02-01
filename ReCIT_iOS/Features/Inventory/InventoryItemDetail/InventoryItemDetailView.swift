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
    @State private var browseEntityDestination: NavigationDestination?

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
        List {
            if let edition = item.edition {
                headerSection(edition: edition)

                Section {
                    UserItemCellView(item: item)
                }

                Section {
                    ForEach(edition.works) { work in
                        Button {
                            browseEntityDestination = NavigationDestination.work(uri: work.uri)
                        } label: {
                            VStack(alignment: .leading, spacing: .small) {
                                Text("Other edition for")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(work.title)
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Livre")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    func headerSection(edition: Edition) -> some View {
        Section {
            EntitySummaryView(entityUri: edition.uri, otherEntityUri: edition.works.first?.uri)

            EntityAuthorsView(
                authors: edition.authors,
                entityDestination: $browseEntityDestination
            )
        } header: {
            EntityHeaderView(
                title: edition.title,
                subtitle: edition.subtitle,
                imageUrl: edition.image
            )
        }
    }
}

