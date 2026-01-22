//
//  EditionView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//
import SwiftData
import SwiftUI

struct EditionView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let edition: Edition
    @Binding var path: NavigationPath

    var inMyInventory: Bool {
        edition.items.first(where: { item in item.owner?.id == userModel.myUser?.id }) != nil
    }

    @State private var errorMessage: String?
    @State private var addingItem: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .medium) {
                EditionHeaderView(edition: edition)
                    .padding(.horizontal, .medium)

                ScrollView(.horizontal) {
                    HStack(spacing: .small) {
                        ForEach(edition.items) { item in
                            if let owner = item.owner {
                                UserCellView(user: owner, description: "Dans l'inventaire de")
                            }
                        }
                    }
                    .padding(.horizontal, .medium)
                }

                if !inMyInventory {
                    addButton
                        .padding(.horizontal, .medium)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: .small) {
                        ForEach(edition.works) { work in
                            Button {
                                path.append(EntityDestination.work(uri: work.uri))
                            } label: {
                                Text(work.title)
                            }
                            .frame(maxWidth: 150)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal, .medium)
                }
            }
        }
    }

    @ViewBuilder
    var addButton: some View {
        if addingItem {
            ProgressView()
        } else {
            Button("Ajouter") {
                Task {
                    await addToInventory()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    @MainActor
    private func addToInventory() async {
        errorMessage = nil
        guard let user = userModel.myUser else {
            errorMessage = "Pas de user connecté !"
            return
        }

        addingItem = true
        do {
            _ = try await inventoryModel.postNewItem(
                modelContext: modelContext,
                entityUri: edition.uri,
                transaction: .inventorying,
                visibility: [.friends],
                forUser: user
            )
            dismiss()
        } catch {
            errorMessage = "Impossible d'ajouter ce livre à votre inventaire."
        }
        addingItem = false
    }
}

#Preview {
    
}
