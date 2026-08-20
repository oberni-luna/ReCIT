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
    @Environment(GenreEnrichmentModel.self) private var genreEnrichmentModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    @State private var viewModel: BookViewModel
    @State private var nextEntityDestination: NavigationDestination?
    @State private var showAddToListDialog: Bool = false
    @State private var addToListItemForm: EntityList?
    @State private var borrowFromItem: InventoryItem?
    @State private var showDeleteConfirmation: Bool = false

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
                // Keyed on the works rather than on the edition, because a cached edition can
                // gain a work when the background refresh lands, and that new work needs asking
                // about too.
                .task(id: edition.works.map(\.uri).sorted()) {
                    await enrichGenres(for: edition)
                }
            case .error(let error):
                Text("error.with_message \(error.localizedDescription)")
            case .noResult:
                Text("edition.no_result")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(item: $borrowFromItem) { item in
            if let owner = item.owner, let me = userModel.myUser {
                TransactionFormView(
                    transaction: .init(
                        _id: "",
                        _rev: "",
                        item: item,
                        owner: owner,
                        requester: me,
                        type: item.transaction,
                        created: .now,
                        messages: [],
                        state: .requested,
                        actions: [],
                        readStatus: .init(owner: false, requester: true)
                    ),
                    transition: TransactionStateMachine.requestTransition
                )
            }
        }
        .confirmationDialog(
            "inventory.item.delete_confirm",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("inventory.item.remove_from_inventory", role: .destructive) {
                Task {
                    await deleteOwnedItem()
                }
            }
            Button("action.cancel", role: .cancel) { }
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
        ToolbarItem(placement: .confirmationAction) {
            if case .loaded(let edition) = viewModel.viewState {
                Menu {
                    if iOwn(edition) == nil {
                        Button("action.add_to_inventory", systemImage: "plus") {
                            Task {
                                await addToInventory(edition: edition)
                            }
                        }

                        let lenders: [InventoryItem] = borrowableItems(edition)
                        if !lenders.isEmpty {
                            Menu("action.borrow_from", systemImage: "hand.wave") {
                                ForEach(lenders) { item in
                                    if let owner = item.owner {
                                        Button(owner.username) {
                                            borrowFromItem = item
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button("action.add_to_list", systemImage: "list.bullet") {
                        showAddToListDialog = true
                    }

                    // Étagères hold a specific copy, so filing is offered only on mine.
                    if let myItem = iOwn(edition) {
                        BookShelfMenu(item: myItem)
                    }

                    if iOwn(edition) != nil {
                        Button("inventory.item.remove_from_inventory", systemImage: "trash", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .tint(.foregroundError)
                    }
                } label: {
                    Label("action.more", systemImage: "ellipsis")
                }
            }
        }
    }

    /// The first five distinct other owners of this edition — the people I could
    /// ask to borrow it from. (ADR 0002 follow-up: the request-to-borrow flow.)
    private func borrowableItems(_ edition: Edition) -> [InventoryItem] {
        var seenOwners: Set<String> = []
        return edition.items
            .filter { $0.ownerId != userModel.myUser?._id && $0.owner != nil && $0.transaction != .inventorying }
            .filter { seenOwners.insert($0.ownerId).inserted }
            .prefix(5)
            .map { $0 }
    }

    @ViewBuilder
    func headerSection(edition: Edition) -> some View {
        Section {
            EntitySummaryView(
                entityUri: edition.uri,
                otherEntityUri: edition.works.first?.uri,
                tags: genres(of: edition)
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
        let canBorrow: Bool = iOwn(edition) == nil
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
                    .contextMenu {
                        if canBorrow, let owner = item.owner {
                            if item.transaction == .inventorying {
                                Button("community.owner_not_lending \(owner.username)", systemImage: "hand.raised.slash") { }
                                    .disabled(true)
                            } else {
                                Button("action.borrow_from_user \(owner.username)", systemImage: "hand.wave") {
                                    borrowFromItem = item
                                }
                            }
                        }
                    }
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

    /// The genres to show as tags, read off the `Work` objects themselves rather than taken from
    /// an enrichment call's return value — so the row appears on its own the moment the fetch
    /// below writes them, and reappears after any later sync. (ADR 0001, invariant 1.)
    ///
    /// Works are sorted so a two-work edition draws its tags in a stable order; within a work
    /// the stored order is the claims' own, which is the order the labels were resolved in.
    private func genres(of edition: Edition) -> [String] {
        var seen: Set<String> = []
        return edition.works
            .sorted(by: { $0.uri < $1.uri })
            .flatMap(\.genres)
            .filter { seen.insert($0).inserted }
    }

    /// Fills in the genres for the works behind this book, at most once each.
    ///
    /// The backfill this delegates to only ever covers the works behind *unshelved* books, since
    /// that is what the arrangement sorts. A book filed by hand — or any book at all in a library
    /// where the arrangement was never run — is therefore never enriched by it, and would show no
    /// tags, which reads as the feature not working rather than as data missing. So the screen
    /// asks for its own.
    ///
    /// In `task`, so it starts after the first paint and never delays it. Asking twice is stopped
    /// in the model, by the timestamp it stores on each work.
    @MainActor
    private func enrichGenres(for edition: Edition) async {
        for work in edition.works {
            await genreEnrichmentModel.enrichWorkIfNeeded(work, modelContext: modelContext)
        }
    }

    /// Removes my copy of the edition after confirmation. No dismiss — the book
    /// screen stays; the "my copy" section drops and the add-to-inventory action
    /// reappears reactively once the item is gone.
    @MainActor
    private func deleteOwnedItem() async {
        guard case .loaded(let edition) = viewModel.viewState, let item = iOwn(edition) else { return }

        do {
            try await inventoryModel.removeItem(item, modelContext: modelContext)
            snackBar.show {
                SnackBarView(title: String(localized: "inventory.item.deleted"), onDismiss: nil)
            }
        } catch {
            snackBar.show { SnackBarView.error(error) }
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
