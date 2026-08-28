//
//  NewListFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import LBSnackBar
import SwiftData

struct ListFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.snackBar) private var snackBar
    @Environment(ListModel.self) var listModel

    @Bindable var list: EntityList = .init(_id: "", _rev: "", name: "", explanation: "", created: Date(), visibility: [], type: .work)

    /// Whether this form is making a list or editing one. A list only has a server id once the
    /// server has answered, so an empty id is what "does not exist yet" means here.
    ///
    /// Read by everything that differs between the two modes — the title, the type picker and
    /// the delete control — because those three disagreeing is exactly how the form came to
    /// offer deleting a list that had never existed.
    private var isCreating: Bool {
        list._id.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if isCreating {
                    Section {
                        Picker("list.form.type", selection: $list.type) {
                            ForEach(EntityListType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .foregroundStyle(.foregroundDefault)
                    }
                }

                Section {
                    TextField("list.form.name", text: $list.name)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "list.form.name")

                    TextEditor(text: $list.explanation)
                        .frame(minHeight: 48)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "list.form.description")
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
                        .buttonStyle(.primary())

                        // Only an existing list can be deleted. The same test decides the
                        // title and the type picker above: a list with no server id has
                        // never existed, so offering to delete it asked the endpoint to
                        // remove an empty id.
                        if !isCreating {
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
                            .buttonStyle(.destructive())
                        }
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .applyListBackground()
            .navigationTitle(isCreating ? String(localized: "list.form.create_title") : String(localized: "list.form.edit_title"))
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
