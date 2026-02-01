//
//  AddToListButton.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 31/01/2026.
//

import SwiftUI
import SwiftData

struct AddToListButton: View {
    @Query(sort: \EntityList.name) var entityLists: [EntityList]
    @EnvironmentObject var listModel: ListModel

    let workUri: String

    var body: some View {
        Menu("Add to a list") {
            ForEach(entityLists) { entityList in
                Button(entityList.name) {
                    Task {
                        try await listModel.addEntitiesToList(listId: entityList._id, entityUris: [workUri])
                    }
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
