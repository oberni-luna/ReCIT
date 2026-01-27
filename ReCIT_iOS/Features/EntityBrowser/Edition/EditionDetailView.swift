//
//  EditionView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//
import SwiftData
import SwiftUI

struct EditionDetailView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loadingEdition
        case loaded(edition: Edition)
        case error(error: Error)
        case noResult
    }

    let editionUri: String
    @State var viewState: ViewState = .loadingEdition
    @Binding var path: NavigationPath

    var inMyInventory: Bool {
        switch viewState {
        case .loaded(edition: let edition):
            edition.items.first(where: { item in item.owner?.id == userModel.myUser?.id }) != nil
        default:
            false
        }
    }

    @State private var errorMessage: String?
    @State private var addingItem: Bool = false

    var body: some View {
        Group {
            switch viewState {
            case .noResult:
                Text("Cette edition n'existe pas sur inventaire.io")
            case .error(error: let error):
                Text("Error loading edition \(error.localizedDescription)")
            case .loadingEdition:
                Text("loading edition")
            case .loaded(edition: let edition):
                ScrollView {
                    VStack(alignment: .leading, spacing: .medium) {
                        EditionHeaderView(
                            edition: edition,
                            entityDestination: Binding<EntityDestination?>(
                                get: { nil },
                                set: { destination in path.append(destination) }
                            )
                        )
                        .padding(.horizontal, .medium)

                        EditionAuthorsView(edition: edition, entityDestination: Binding<EntityDestination?>(
                            get: { nil },
                            set: { destination in path.append(destination) }
                        ))

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
                            addButton(edition: edition)
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

                                    ForEach(work.authors) { author in
                                        Button {
                                            path.append(EntityDestination.author(uri: author.uri))
                                        } label: {
                                            Text(author.name)
                                        }
                                        .frame(maxWidth: 150)
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                            .padding(.horizontal, .medium)
                        }
                    }
                }
            }
        }
        .navigationTitle("Edition")
        .onAppear {
            Task { await loadEdition() }
        }
    }

    @ViewBuilder
    func addButton(edition: Edition) -> some View {
        if addingItem {
            ProgressView()
        } else {
            Button("Ajouter") {
                Task {
                    await addToInventory(edition: edition)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    @MainActor
    private func loadEdition() async {
        do {
            if let editions = try await inventoryModel.getOrFetchEditions(modelContext: modelContext, uris: [editionUri]), let edition = editions.first {
                viewState = .loaded(edition: edition)
            } else {
                viewState = .noResult
            }
        } catch {
            viewState = .error(error: error)
        }
    }

    @MainActor
    private func addToInventory(edition: Edition) async {
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
