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
//  merge into BookDetailView. Notes are edited in place (no sheet); deletion
//  lives in the screen's toolbar menu.
//

import SwiftUI
import SwiftData

struct BookMyCopySection: View {
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(\.modelContext) private var modelContext

    @Bindable var item: InventoryItem

    @State private var draftDetails: String
    @FocusState private var notesFocused: Bool

    init(item: InventoryItem) {
        _item = Bindable(item)
        _draftDetails = State(initialValue: item.details)
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
            TextField(
                "inventory.item.write_notes",
                text: $draftDetails,
                axis: .vertical
            )
            .textStyle(.content300)
            .foregroundStyle(.foregroundDefault)
            .withLabel(label: String(localized: "inventory.item.my_notes"))
            .focused($notesFocused)
            .onChange(of: notesFocused) { _, focused in
                if !focused {
                    commitNotes()
                }
            }
            .onChange(of: item.details) { _, newValue in
                // Keep the field in sync with background syncs / optimistic
                // reverts, but never clobber what the user is currently typing.
                if !notesFocused {
                    draftDetails = newValue
                }
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
        }
    }

    /// Persists the edited note optimistically when the field loses focus, but
    /// only when it actually changed.
    private func commitNotes() {
        guard draftDetails != item.details else { return }
        inventoryModel.updateItemDetailsOptimistic(
            item: item,
            details: draftDetails,
            modelContext: modelContext
        )
    }
}
