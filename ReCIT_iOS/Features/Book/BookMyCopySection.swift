//
//  BookMyCopySection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//
//  The "Ton exemplaire" overlay of the unified book screen (ADR 0002, Move 1 /
//  P3). Folds the editable content of the old InventoryItemDetailView — notes
//  and the transaction-mode picker — onto a `@Bindable` item so the two-way
//  picker binding and the optimistic writes (ADR 0001, invariant 3) survive the
//  merge into BookDetailView. Notes are edited in place (no sheet) and saved
//  automatically as the user types; deletion
//  lives in the screen's toolbar menu.
//

import SwiftUI
import SwiftData

struct BookMyCopySection: View {
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(\.modelContext) private var modelContext

    @Bindable var item: InventoryItem

    init(item: InventoryItem) {
        _item = Bindable(item)
    }

    var body: some View {
        // The section is already gated on `iOwn(edition)` by the screen, but the gate and this
        // body are not evaluated together: deleting the item invalidates this view first, and
        // every line below reads a persisted property. See `PersistentModel+StillInTheStore`.
        if item.isStillInTheStore {
            section
        }
    }

    private var section: some View {
        Section("edition.my_inventory") {
            AutosavingTextField(
                "inventory.item.my_notes",
                placeholder: "inventory.item.write_notes",
                value: item.details,
                identifier: AccessibilityID.details,
                save: { save($0, to: .details) }
            )

            AutosavingTextField(
                "inventory.item.private_note",
                placeholder: "inventory.item.write_private_note",
                value: item.notes,
                identifier: AccessibilityID.notes,
                save: { save($0, to: .notes) }
            )

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
        }
    }

    /// Persists an edited text optimistically — after a pause in typing, on focus
    /// loss, or on leaving the screen — but only when it actually changed.
    private func save(_ text: String, to attribute: InventoryItemTextAttribute) {
        guard item.isStillInTheStore, text != item[keyPath: attribute.keyPath] else { return }
        inventoryModel.updateItemTextOptimistic(
            item: item,
            attribute: attribute,
            text: text,
            modelContext: modelContext
        )
    }
}

private extension BookMyCopySection {
    enum AccessibilityID {
        static let details: String = "e2e.book.details"
        static let notes: String = "e2e.book.notes"
    }
}
