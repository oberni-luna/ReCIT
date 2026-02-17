//
//  InventoryItemDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 28/11/2025.
//
import SwiftData
import SwiftUI
import LBSnackBar

struct InventoryItemDetailView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject var inventoryModel: InventoryModel
    @EnvironmentObject var listModel: ListModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.snackBar) private var snackBar

    @State private var showDeleteConfirmation = false
    @State private var browseEntityDestination: NavigationDestination?
    @State private var transaction: UserTransaction?

    @Bindable var item: InventoryItem
    @Binding var path: NavigationPath

    var isMyItem: Bool {
        item.owner?._id == userModel.myUser?._id
    }

    var hasDetails: Bool {
        item.details.isEmpty == false
    }

    var body: some View {
        itemContentView
            .toolbar {
                toolbarContent()
            }
            .confirmationDialog("Supprimer cet item de votre inventaire ?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    Task {
                        do {
                            try await inventoryModel.removeItem(item, modelContext: modelContext)
                            snackBar.show {
                                SnackBarView(
                                    title: "Supprimé !", onDismiss: {dismiss()})
                            }
                            dismiss()
                        } catch {
                            snackBar.show {
                                SnackBarView(title: "Une erreur s'est produite", subtitle: "\(error.localizedDescription)", onDismiss: {dismiss()})
                            }
                        }
                    }
                }
                Button("Annuler", role: .cancel) { }
            }
            .selectListToAdd(
                showAddToListDialog: $showAddToListDialog,
                onListSelected: { list in
                    Task {
                        do {
                            try await listModel.addEntitiesToList(
                                listId: list._id,
                                entityUris: item.workUris
                            )
                            snackBar.show {
                                SnackBarView(
                                    title: "\(item.edition?.title ?? "Ce livre ")", subtitle: "a bien été ajouté à la liste", onDismiss: {dismiss()})
                            }
                        } catch {
                            snackBar.show {
                                SnackBarView(title: "Une erreur s'est produite", subtitle: "\(error.localizedDescription)", onDismiss: {dismiss()})
                            }
                        }
                    }
                })
            .sheet(isPresented: $showItemDetailsForm) {
                InventoryItemDetailsFormView(item: item)
            }
            .onChange(of: browseEntityDestination) { _, destination in
                if let destination {
                    path.append(destination)
                    browseEntityDestination = nil
                }
            }
            .sheet(isPresented: $showTransactionForm) {
                if let transaction = self.transaction {
                    TransactionFormView(transaction: transaction)
                } else {
                    if !isMyItem, let user = userModel.myUser, let owner = item.owner {
                        TransactionFormView(transaction:
                            UserTransaction.init(
                                _id: "", _rev: "",
                                item: item,
                                owner: owner,
                                requester: user,
                                type: item.transaction,
                                created: Date(),
                                messages: [],
                                state: .requested,
                                actions: [],
                                readStatus: .init(owner: false, requester: true)
                            )
                        )
                    }
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
            if !item.details.isEmpty {
                Text(item.details)
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

    @State private var showAddToListDialog: Bool = false
    @State private var showItemDetailsForm: Bool = false
    @State private var showTransactionForm: Bool = false

    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if !isMyItem {
                    Button {
                        showTransactionForm = true
                    } label: {
                        Label("Envoyer une demander", systemImage: "questionmark.message")
                    }
                }

                Button {
                    showAddToListDialog = true
                } label: {
                    Label("Add to a list", systemImage: "list.bullet")
                }

                if isMyItem {
                    Button {
                        showItemDetailsForm = true
                    } label: {
                        Label(hasDetails ? "Changer mon commentaire" : "Écrire un commentaire", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
}

