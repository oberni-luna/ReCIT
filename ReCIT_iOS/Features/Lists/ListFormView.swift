//
//  NewListFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI

struct ListFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var listModel: ListModel

    @Bindable var list: EntityList = .init(_id: "", _rev: "", name: "", explanation: "", created: Date(), visibility: [], type: .work)

    var body: some View {
        NavigationStack {
            Form {
                if list._id.isEmpty {
                    Section {
                        Picker("Type", selection: $list.type) {
                            ForEach(EntityListType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        TextField("Name", text: $list.name)
                    }
                    VStack(alignment: .leading, spacing: .xSmall) {
                        Text("Descrition")
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
                    AsyncButton(action: {
                        do {
                            try await listModel.createOrUpdateList(
                                modelContext: modelContext,
                                list: list
                            )
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
            .navigationTitle(list._id.isEmpty ? "Create new list" : "Edit list")
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

#Preview {
    ListFormView()
}
