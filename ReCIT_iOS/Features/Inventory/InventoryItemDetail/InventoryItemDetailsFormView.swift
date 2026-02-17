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
                        .withLabel(label: "Ce que j'en pense")
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    AsyncButton(action: {
                        do {
                            try await InventoryModel.updateItemsDetails(modelContext: modelContext, items: [item])
                            snackBar.show {
                                SnackBarView(title: "Description enregistrée", onDismiss: {dismiss()})
                            }
                            dismiss()
                        } catch {
                            snackBar.show {
                                SnackBarView(title: "Une erreur s'est produite", subtitle: "\(error.localizedDescription)", onDismiss: {dismiss()})
                            }
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
