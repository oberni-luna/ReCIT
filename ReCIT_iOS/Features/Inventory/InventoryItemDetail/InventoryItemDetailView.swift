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
    @State private var addToListItemForm: EntityList? = nil

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
            .confirmationDialog("inventory.item.delete_confirm", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("action.delete", role: .destructive) {
                    Task {
                        do {
                            try await inventoryModel.removeItem(item, modelContext: modelContext)
                            snackBar.show {
                                SnackBarView(
                                    title: String(localized: "inventory.item.deleted"), onDismiss: {dismiss()})
                            }
                            dismiss()
                        } catch {
                            snackBar.show {
                                SnackBarView(title: String(localized: "error.generic"), subtitle: "\(error.localizedDescription)", onDismiss: {dismiss()})
                            }
                        }
                    }
                }
                Button("action.cancel", role: .cancel) { }
            }
            .selectListToAdd(
                showAddToListDialog: $showAddToListDialog,
                onListSelected: { list in
                    addToListItemForm = list
                })
            .sheet(item: $addToListItemForm) { list in
                if let work = item.edition?.works.first {
                    ListItemFormView(entity: work, list: list)
                }
            }
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
                            NavigationLink(value: UUID()) {
                                Text(work.title)
                                    .textStyle(.content400Bold)
                                    .lineLimit(1)
                                    .withLabel(label: String(localized: "inventory.item.other_edition_for"))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .applyListBackground()
        .navigationTitle("nav.book")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    var myItemSection: some View {
        Section {
            if !item.details.isEmpty {
                Text(item.details)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: String(localized: "inventory.item.my_notes"))
            }

            HStack {
                Text("inventory.item.created_date \(item.created.formatted(date: .abbreviated, time: .omitted))")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)

                Spacer()

                Picker("inventory.item.transaction_mode", selection: $item.transaction) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        TransactionTypeLabel(transactionType: type)
                    }
                }
                .labelsHidden()
                .onChange(of: item.transaction) { _, transactionMode in
                    Task {
                        try? await inventoryModel.updateItemsTransaction(modelContext: modelContext, items: [item])
                    }
                }
            }
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
                        Label("action.send_request", systemImage: "questionmark.message")
                            .foregroundStyle(.foregroundDefault)
                            .textStyle(.action300)
                    }
                }

                Button {
                    showAddToListDialog = true
                } label: {
                    Label("action.add_to_list", systemImage: "list.bullet")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundDefault)
                }

                if isMyItem {
                    Button {
                        showItemDetailsForm = true
                    } label: {
                        Label(hasDetails ? String(localized: "inventory.item.change_notes") : String(localized: "inventory.item.write_notes"), systemImage: "pencil")
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundDefault)
                    }

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Label("action.delete", systemImage: "trash")
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundError)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
}

