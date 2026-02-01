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
    @State private var nextEntityDestination: EntityDestination?
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
        List {
            switch viewState {
            case .loadingEdition:
                ProgressView()
            case .loaded(edition: let edition):
                headerSection(edition: edition)
                userInventorySection(edition: edition)

                if !inMyInventory {
                    Section {
                        addToInventoryButton(edition: edition)
                    }
                }
            case .error(error: let error):
                Text("Error loading edition \(error.localizedDescription)")
            case .noResult:
                Text("Cette edition n'existe pas sur inventaire.io")
            }
        }
        .navigationTitle("Edition")
        .toolbar {
            toolbarContent
        }
        .onAppear {
            Task { await loadEdition() }
        }
        .onChange(of: nextEntityDestination) { _, destination in
            if let destination {
                path.append(destination)
                nextEntityDestination = nil
            }
        }
    }

    @ToolbarContentBuilder
    var toolbarContent : some ToolbarContent {
        ToolbarItemGroup(placement: .confirmationAction) {
            switch viewState {
            case .loaded(let edition):
                Button("Add to inventory", systemImage: "plus") {
                    Task {
                        await addToInventory(edition: edition)
                    }
                }
            case .loadingEdition, .error, .noResult:
                EmptyView()
            }
        } label: {
            Image(systemName: "ellipsis")
                .imageScale(.large)
        }
    }

    @ViewBuilder
    func headerSection(edition: Edition) -> some View {
        Section {
            EntitySummaryView(entityUri: edition.uri, otherEntityUri: edition.works.first?.uri)

            EntityAuthorsView(
                authors: edition.authors,
                entityDestination: $nextEntityDestination
            )
        } header: {
            EntityHeaderView(
                title: edition.title,
                subtitle: edition.subtitle,
                imageUrl: edition.image
            )
        }
    }

    @ViewBuilder
    func userInventorySection(edition: Edition) -> some View {
        if !edition.items.isEmpty {
            Section("Dans l'inventaire de") {
                ForEach(edition.items) { item in
//                    if item.owner?.id != userModel.myUser?.id {
                        UserItemCellView(item: item)
//                    }
                }
            }
        }
    }

    @ViewBuilder
    func addToInventoryButton(edition: Edition) -> some View {
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
        } catch {
            errorMessage = "Impossible d'ajouter ce livre à votre inventaire."
        }
        addingItem = false
    }
}

#Preview {
    
}
