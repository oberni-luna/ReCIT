//
//  NewListFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI

struct NewListFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var listModel: ListModel

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var type: EntityListType = .work

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(EntityListType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section {
                    TextField("Name", text: $name)
                    TextEditor(text: $description)
                }
            }
            AsyncButton(action: {
                do {
                    try await listModel.createList(
                        modelContext: modelContext,
                        name: name,
                        description: description,
                        type: type.rawValue,
                        visibility: []
                    )
                    dismiss()
                } catch {
                    print(error)
                }
            },
                        actionOptions: [.showProgressView],
                        label: {
                Text("Submit")
            })
        }
        .navigationTitle("Create new list")
    }
}

#Preview {
    NewListFormView()
}
