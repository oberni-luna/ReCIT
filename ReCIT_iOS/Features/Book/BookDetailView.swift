//
//  BookDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//
//  The unified book screen (ADR 0002, Move 1). Anchored on an Edition, it
//  reaches parity with the old EditionDetailView: header, the works the edition
//  contains, who owns it in the community, and my own copy. The ownership
//  overlay is read-only here — folding in item editing (notes, transactions) is
//  P3.
//

import SwiftUI
import SwiftData
import LBSnackBar

struct BookDetailView: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(UserModel.self) private var userModel
    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    @State private var viewModel: BookViewModel
    @State private var nextEntityDestination: NavigationDestination?
    @State private var showAddToListDialog: Bool = false
    @State private var addToListItemForm: EntityList?

    @Binding var path: NavigationPath

    init(
        anchor: BookAnchor,
        path: Binding<NavigationPath>
    ) {
        _viewModel = State(initialValue: .init(anchor: anchor))
        _path = path
    }

    private func iOwn(_ edition: Edition) -> InventoryItem? {
        edition.items.first { $0.ownerId == userModel.myUser?._id }
    }

    var body: some View {
        VStack {
            switch viewModel.viewState {
            case .loading:
                ProgressView()
            case .loaded(let edition):
                List {
                    headerSection(edition: edition)
                    otherEditionsSection()
                    communitySection(edition: edition)
                    myCopySection(edition: edition)
                }
                .applyListBackground()
                .selectListToAdd(
                    showAddToListDialog: $showAddToListDialog,
                    onListSelected: { list in
                        if edition.workUris.count > 1 {
                            listModel.addEntitiesToList(
                                modelContext: modelContext,
                                list: list,
                                entityUris: edition.workUris
                            )
                        } else if edition.works.first != nil {
                            addToListItemForm = list
                        }
                    }
                )
                .sheet(item: $addToListItemForm) { list in
                    if let work = edition.works.first {
                        ListItemFormView(entity: work, list: list)
                    }
                }
            case .error(let error):
                Text("error.with_message \(error.localizedDescription)")
            case .noResult:
                Text("edition.no_result")
            }
        }
        .navigationTitle("nav.book")
        .toolbar {
            toolbarContent
        }
        .task {
            await viewModel.load(entityModel: entityModel, modelContext: modelContext)
        }
        .onChange(of: nextEntityDestination) { _, destination in
            if let destination {
                path.append(destination)
                nextEntityDestination = nil
            }
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .confirmationAction) {
            switch viewModel.viewState {
            case .loaded(let edition):
                if iOwn(edition) == nil {
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

            case .loading, .error, .noResult:
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

    /// A link to the other editions of each underlying work that actually has
    /// some. A work with only this one edition contributes no row; when no
    /// underlying work has siblings the section is absent entirely. Tapping opens
    /// the work's edition gateway (the picker). (ADR 0002)
    @ViewBuilder
    func otherEditionsSection() -> some View {
        if !viewModel.worksWithOtherEditions.isEmpty {
            Section {
                ForEach(viewModel.worksWithOtherEditions.sorted(by: { $0.title < $1.title })) { work in
                    Button {
                        nextEntityDestination = NavigationDestination.work(uri: work.uri)
                    } label: {
                        NavigationLink(value: UUID()) {
                            OtherEditionsCell(work: work)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    func communitySection(edition: Edition) -> some View {
        let othersItems: [InventoryItem] = edition.items.filter { $0.ownerId != userModel.myUser?._id }
        if !othersItems.isEmpty {
            Section("nav.community") {
                ForEach(othersItems) { item in
                    Button {
                        if let owner = item.owner {
                            nextEntityDestination = NavigationDestination.user(user: owner)
                        }
                    } label: {
                        NavigationLink(value: UUID()) {
                            UserItemCellView(item: item)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Ownership overlay — editable. Delegates to `BookMyCopySection`, which owns
    /// the `@Bindable` item so the transaction picker and optimistic writes keep
    /// working after the fold. (ADR 0002, P3)
    @ViewBuilder
    func myCopySection(edition: Edition) -> some View {
        if let item = iOwn(edition) {
            BookMyCopySection(item: item)
        }
    }

    @MainActor
    private func addToInventory(edition: Edition) async {
        guard let user = userModel.myUser else {
            snackBar.show { SnackBarView(title: String(localized: "edition.error.no_user"), onDismiss: nil) }
            return
        }

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
