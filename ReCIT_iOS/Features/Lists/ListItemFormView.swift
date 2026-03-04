//
//  NewListFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI

struct ListItemFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var listModel: ListModel

    @Bindable var listItem: EntityListItem
    let list: EntityList
    let entity: any Entity

    init(entity: any Entity, list: EntityList, listItem: EntityListItem? = nil) {
        self.entity = entity
        self.list = list

        if let listItem {
            self.listItem = listItem
        } else {
            self.listItem = .init(_id: "", uri: entity.uri, ordinal: "", created: Date(), itemType: .work, list: list)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        Text("list.item.comment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        TextEditor(text: $listItem.comment)
                            .frame(minHeight: 48)
                    }
                } header: {
                    EntityHeaderView(
                        title: entity.title,
                        subtitle: entity.subtitle,
                        imageUrl: entity.image
                    )
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    VStack {
                        AsyncButton(action: {
                            do {
                                try await listModel.addEntitiesToList(modelContext: modelContext, list: list, entityUris: [entity.uri], comment: listItem.comment)
                                dismiss()
                            } catch {
                                print(error)
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
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .navigationTitle(list.name)
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
