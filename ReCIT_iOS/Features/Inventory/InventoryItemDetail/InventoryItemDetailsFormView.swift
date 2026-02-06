//
//  InventoryItemDetailsFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/02/2026.
//

import Foundation
import SwiftUI

struct InventoryItemDetailsFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var InventoryModel: InventoryModel

    @Bindable var item: InventoryItem

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $item.details)
                        .frame(minHeight: 128)
                        .withLabel(label: "Ce que j'en pense")
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    AsyncButton(action: {
                        do {
                            try await InventoryModel.updateItemsDetails(modelContext: modelContext, items: [item])
                            dismiss()
                        } catch {
                            print(error)
                        }
                    },
                                actionOptions: [.showProgressView],
                                label: {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .navigationTitle(item.edition?.title ?? "")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}
