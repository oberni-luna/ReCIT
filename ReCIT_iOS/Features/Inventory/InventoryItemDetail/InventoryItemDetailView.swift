//
//  InventoryItemDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//
import SwiftData
import SwiftUI

struct InventoryItemDetailView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject var inventoryModel: InventoryModel
    @EnvironmentObject var listModel: ListModel
    @Query(sort: \EntityList.name) var entityLists: [EntityList]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false
    @State private var browseEntityDestination: NavigationDestination?

    @Bindable var item: InventoryItem
    @Binding var path: NavigationPath

    var isMyItem: Bool {
        item.owner?._id == userModel.myUser?._id
    }

    var body: some View {
        itemContentView
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    if isMyItem {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    } else {
                        Button {
                            //
                        } label: {
                            Label("Envoyer une demander", systemImage: "questionmark.message")
                        }
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
            if let edition = item.edition, let owner = item.owner {
                headerSection(edition: edition)

                if isMyItem {
                    myItemSection
                } else {
                    Section {
                        Button {
                            browseEntityDestination = NavigationDestination.user(user: owner)
                        } label: {
                            UserItemCellView(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    ForEach(edition.works) { work in
                        Button {
                            browseEntityDestination = NavigationDestination.work(uri: work.uri)
                        } label: {
                            Text(work.title)
                                .font(.headline)
                                .lineLimit(1)
                                .withLabel(label: "Other edition for")
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
    var myItemSection: some View {
        Section {
            if let details = item.details, !details.isEmpty {
                Text(details)
                    .font(.body)
                    .foregroundStyle(.textDefault)
                    .withLabel(label: "Ce que j'en pense")
            }
            
            Picker("Transaction mode", selection: $item.transaction) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    TransactionTypeLabel(transactionType: type)
                }
            }
            .onChange(of: item.transaction) { _, transactionMode in
                Task {
                    try? await inventoryModel.updateItemsTransaction(modelContext: modelContext, items: [item])
                }
            }

            Text("Created \(item.created.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    func headerSection(edition: Edition) -> some View {
        Section {
            EntitySummaryView(entityUri: edition.uri, otherEntityUri: edition.works.first?.uri)

            EntityAuthorsView(
                authors: edition.authors.sorted(by: { $0.name < $1.name }),
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

