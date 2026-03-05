//
//  NewListFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import LBSnackBar

struct ListFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.snackBar) private var snackBar
    @EnvironmentObject var listModel: ListModel

    @Bindable var list: EntityList = .init(_id: "", _rev: "", name: "", explanation: "", created: Date(), visibility: [], type: .work)

    var body: some View {
        NavigationStack {
            Form {
                if list._id.isEmpty {
                    Section {
                        Picker("list.form.type", selection: $list.type) {
                            ForEach(EntityListType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        Text("list.form.name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        TextField("list.form.name", text: $list.name)
                    }
                    VStack(alignment: .leading, spacing: .xSmall) {
                        Text("list.form.description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        TextEditor(text: $list.explanation)
                            .frame(minHeight: 48)
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    VStack {
                        AsyncButton(action: {
                            do {
                                try await listModel.createOrUpdateList(
                                    modelContext: modelContext,
                                    list: list
                                )
                                dismiss()
                            } catch {
                                snackBar.show { SnackBarView.error(error) }
                            }
                        },
                                    actionOptions: [.showProgressView],
                                    label: {
                            Text("action.submit")
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        AsyncButton(action: {
                            do {
                                try await listModel.deleteList(
                                    modelContext: modelContext,
                                    list: list
                                )
                                dismiss()
                            } catch {
                                snackBar.show { SnackBarView.error(error) }
                            }
                        },
                                    actionOptions: [.showProgressView],
                                    label: {
                            Text("list.form.delete")
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(.borderedProminent)
                        .tint(Color(.red))
                        .controlSize(.large)
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .navigationTitle(list._id.isEmpty ? String(localized: "list.form.create_title") : String(localized: "list.form.edit_title"))
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

#Preview {
    ListFormView()
}
