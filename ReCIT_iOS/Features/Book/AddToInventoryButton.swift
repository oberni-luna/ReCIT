//
//  AddToInventoryButton.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import LBSnackBar
import SwiftData
import SwiftUI

/// Adds the edition to my inventory, as a copy kept for myself and seen by my friends: the line
/// of the book's « … » menu and the pill of Mon exemplaire when I own no copy. Once the copy is
/// in the store, Mon exemplaire shows it on its own.
struct AddToInventoryButton<Label: View>: View {
    private let edition: Edition
    private let label: Label

    @State private var isAdding: Bool = false

    @Environment(InventoryModel.self) private var inventoryModel: InventoryModel
    @Environment(UserModel.self) private var userModel: UserModel
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.snackBar) private var snackBar: SnackBarAction

    init(
        edition: Edition,
        @ViewBuilder label: () -> Label
    ) {
        self.edition = edition
        self.label = label()
    }

    var body: some View {
        Button {
            Task {
                await add()
            }
        } label: {
            label
        }
        // A second tap while the first is on its way would post a second copy.
        .disabled(isAdding)
    }

    private func add() async {
        guard let user = userModel.myUser else {
            snackBar.show { SnackBarView(title: String(localized: "edition.error.no_user"), onDismiss: nil) }
            return
        }

        isAdding = true
        defer { isAdding = false }
        do {
            _ = try await inventoryModel.postNewItem(
                modelContext: modelContext,
                entityUri: edition.uri,
                transaction: .inventorying,
                visibility: [.friends],
                forUser: user
            )
            snackBar.show { SnackBarView(title: String(localized: "edition.added_to_inventory"), onDismiss: nil) }
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}

#Preview {
    AddToInventoryButton(edition: .init(uri: "isbn:9782070360024", title: "L'Étranger", lang: "fr", authorNames: [])) {
        Label("book.my_copy.add_to_inventory", systemImage: "plus")
    }
    .buttonStyle(.pill(.prominent))
}
