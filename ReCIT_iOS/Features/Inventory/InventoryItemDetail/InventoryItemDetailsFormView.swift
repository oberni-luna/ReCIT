//
//  InventoryItemDetailsFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/02/2026.
//

import Foundation
import SwiftUI
import SwiftData
import LBSnackBar

struct InventoryItemDetailsFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var InventoryModel: InventoryModel
    @Environment(\.snackBar) private var snackBar

    @Bindable var item: InventoryItem

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $item.details)
                        .frame(minHeight: 128)
                        .withLabel(label: String(localized: "inventory.item.my_notes"))
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    AsyncButton(action: {
                        do {
                            try await InventoryModel.updateItemsDetails(modelContext: modelContext, items: [item])
                            snackBar.show {
                                SnackBarView(title: String(localized: "inventory.item.details.saved"), onDismiss: {dismiss()})
                            }
                            dismiss()
                        } catch {
                            snackBar.show {
                                SnackBarView(title: String(localized: "error.generic"), subtitle: "\(error.localizedDescription)", onDismiss: {dismiss()})
                            }
                        }
                    },
                                actionOptions: [.showProgressView],
                                label: {
                        Text("action.submit")
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
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}
