//
//  NewListFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import SwiftData

struct ListItemFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(ListModel.self) var listModel

    @Bindable var listItem: EntityListItem
    let list: EntityList
    let entity: any Entity

    init(entity: any Entity, list: EntityList, listItem: EntityListItem? = nil) {
        self.entity = entity
        self.list = list

        if let listItem {
            self.listItem = listItem
        } else {
            self.listItem = .init(_id: "", uri: entity.uri, ordinal: "", created: Date(), itemType: .work)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        TextEditor(text: $listItem.comment)
                            .frame(minHeight: 48)
                            .withLabel(label: "list.item.comment")
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
                        Button(action: {
                            // Optimistic: the element appears in the list immediately.
                            listModel.addEntitiesToList(modelContext: modelContext, list: list, entityUris: [entity.uri], comment: listItem.comment)
                            dismiss()
                        }, label: {
                            Text("action.submit")
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(.primary())
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .applyListBackground()
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
