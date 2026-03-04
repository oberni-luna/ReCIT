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
    @EnvironmentObject var listModel: ListModel
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
    @State private var nextEntityDestination: NavigationDestination?
    @State private var showAddToListDialog: Bool = false
    
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
    @State private var addToListItemForm: EntityList? = nil

    var body: some View {
        VStack {
            switch viewState {
            case .loadingEdition:
                ProgressView()
            case .loaded(edition: let edition):
                List {
                    headerSection(edition: edition)
                    userInventorySection(edition: edition)
                    myInventorySection(edition: edition)
                }
                .selectListToAdd(
                    showAddToListDialog: $showAddToListDialog,
                    onListSelected: { list in
                        if edition.workUris.count > 1 {
                            Task {
                                try await listModel.addEntitiesToList(modelContext: modelContext, list: list, entityUris: edition.workUris)
                            }
                        } else if let _ = edition.works.first {
                            addToListItemForm = list
                        }
                    })
                .selectListToAdd(
                    showAddToListDialog: $showAddToListDialog,
                    onListSelected: { list in
                        addToListItemForm = list
                    })
                .sheet(item: $addToListItemForm) { list in
                    if let work = edition.works.first {
                        ListItemFormView(entity: work, list: list)
                    }
                }
            case .error(error: let error):
                Text("error.with_message \(error.localizedDescription)")
            case .noResult:
                Text("edition.no_result")
            }
        }
        .navigationTitle("nav.edition")
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
                if !inMyInventory {
                    Button("action.add_to_inventory", systemImage: "plus") {
                        Task {
                            await addToInventory(edition: edition)
                        }
                    }
                }
                
                Button {
                    showAddToListDialog = true
                } label: {
                    Label("action.add_to_list", systemImage: "list.bullet")
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
            EntitySummaryView(
                entityUri: edition.uri,
                otherEntityUri: edition.works.first?.uri
            )

            EntityAuthorsView(
                authors: edition.authors.sorted(by: { $0.name < $1.name }),
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
        if !edition.items.filter({$0.owner?.id != userModel.myUser?.id}).isEmpty {
            Section("edition.others_inventory") {
                ForEach(edition.items.filter({$0.owner?.id != userModel.myUser?.id})) { item in
                    Button {
                        if let owner = item.owner {
                            nextEntityDestination = NavigationDestination.user(user: owner)
                        }
                    } label: {
                        UserItemCellView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    func myInventorySection(edition: Edition) -> some View {
        if let item = edition.items.filter({$0.owner?.id == userModel.myUser?.id}).first {
            Section("edition.my_inventory") {
                Button {
                    nextEntityDestination = NavigationDestination.item(item: item)
                } label: {
                    UserItemCellView(item: item)
                }
                .buttonStyle(.plain)
            }
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
            errorMessage = String(localized: "edition.error.no_user")
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
            errorMessage = String(localized: "edition.error.add_failed")
        }
        addingItem = false
    }
}

#Preview {
    
}
