//
//  SelectListToAddModifier.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/02/2026.
//
import SwiftData
import SwiftUI

public extension View {
    func selectListToAdd(
        showAddToListDialog: Binding<Bool>,
        onListSelected: @escaping (EntityList) -> Void
    ) -> some View {
        self.modifier(SelectListToAddModifier(
            showAddToListDialog: showAddToListDialog,
            onListSelected: onListSelected
        ))
    }
}

struct SelectListToAddModifier: ViewModifier {
    @EnvironmentObject var listModel: ListModel
    @Query(sort: \EntityList.name) var entityLists: [EntityList]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var showAddToListDialog: Bool
    let onListSelected: (EntityList) -> Void

    func body(content: Content) -> some View {
        content
            .alert("Pick list", isPresented: $showAddToListDialog) {
            Group {
                ForEach(entityLists) { entityList in
                    Button(entityList.name, role:.confirm) {
                        onListSelected(entityList)
                        showAddToListDialog = false
                    }
                }
            }
            Button("Annuler", role: .cancel){ }
        } message: {
            Text("Select the list you want to add this item to.")
        }
    }
}

