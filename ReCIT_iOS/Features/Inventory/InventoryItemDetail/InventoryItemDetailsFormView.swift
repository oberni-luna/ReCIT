//
//  InventoryItemDetailsFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/02/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct InventoryItemDetailsFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(InventoryModel.self) var inventoryModel

    let item: InventoryItem
    @State private var draft: String

    init(item: InventoryItem) {
        self.item = item
        _draft = State(initialValue: item.details)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $draft)
                        .frame(minHeight: 128)
                        .withLabel(label: String(localized: "inventory.item.my_notes"))
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    Button(action: {
                        // Optimistic: persists locally now, pushes in the background,
                        // reverts + surfaces an error via the shared reporter on failure.
                        inventoryModel.updateItemDetailsOptimistic(item: item, details: draft, modelContext: modelContext)
                        dismiss()
                    }, label: {
                        Text("action.submit")
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(.primary())
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .applyListBackground()
            .navigationTitle(item.edition?.title ?? "")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}
