//
//  BookMyCopySection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//
//  The "Ton exemplaire" overlay of the unified book screen (ADR 0002, Move 1 /
//  P3). Folds the editable content of the old InventoryItemDetailView — notes,
//  the transaction-mode picker, and delete — onto a `@Bindable` item so the
//  two-way picker binding and the optimistic writes (ADR 0001, invariant 3)
//  survive the merge into BookDetailView.
//

import SwiftUI
import SwiftData
import LBSnackBar

struct BookMyCopySection: View {
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    @Bindable var item: InventoryItem

    @State private var showItemDetailsForm: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    private var hasDetails: Bool {
        item.details.isEmpty == false
    }

    var body: some View {
        Section("edition.my_inventory") {
            if hasDetails {
                Button {
                    showItemDetailsForm = true
                } label: {
                    Text(item.details)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: String(localized: "inventory.item.my_notes"))
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text("inventory.item.created_date \(item.created.formatted(date: .abbreviated, time: .omitted))")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)

                Spacer()

                Picker("inventory.item.transaction_mode", selection: $item.transaction) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        type.label
                    }
                }
                .labelsHidden()
                .onChange(of: item.transaction) { previous, newValue in
                    inventoryModel.updateItemTransactionOptimistic(
                        item: item,
                        newValue: newValue,
                        previous: previous,
                        modelContext: modelContext
                    )
                }
            }

            Button(
                hasDetails ? "inventory.item.change_notes" : "inventory.item.write_notes",
                systemImage: "pencil"
            ) {
                showItemDetailsForm = true
            }

            Button("action.delete", systemImage: "trash", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
        .sheet(isPresented: $showItemDetailsForm) {
            InventoryItemDetailsFormView(item: item)
        }
        .confirmationDialog(
            "inventory.item.delete_confirm",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("action.delete", role: .destructive) {
                Task {
                    await deleteItem()
                }
            }
            Button("action.cancel", role: .cancel) { }
        }
    }

    @MainActor
    private func deleteItem() async {
        do {
            try await inventoryModel.removeItem(item, modelContext: modelContext)
            snackBar.show {
                SnackBarView(title: String(localized: "inventory.item.deleted"), onDismiss: nil)
            }
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}
