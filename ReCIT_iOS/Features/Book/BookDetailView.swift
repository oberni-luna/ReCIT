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

struct BookDetailView: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(UserModel.self) private var userModel
    @Environment(GenreEnrichmentModel.self) private var genreEnrichmentModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: BookViewModel
    @State private var nextEntityDestination: NavigationDestination?
    @State private var borrowFromItem: InventoryItem?
    /// How many times this screen has been asked to load. Bumped by « Réessayer », and the
    /// `.task` key — which is how a retry re-runs a call that nothing else about the screen has
    /// changed. One way in, so loading, the book, the two absences and the failure are decided
    /// in one place. Same shape as `InventorySearchContent`'s.
    @State private var attempt: Int = 0

    @Binding var path: NavigationPath

    init(
        anchor: BookAnchor,
        path: Binding<NavigationPath>
    ) {
        _viewModel = State(initialValue: .init(anchor: anchor))
        _path = path
    }

    private var loadedEdition: Edition? {
        if case .loaded(let edition) = viewModel.viewState {
            return edition
        }
        return nil
    }

    /// My copy of this edition, if I have one.
    ///
    /// The `isStillInTheStore` test comes first because this runs on the screen that does the
    /// deleting: `edition.items` can still hold the copy that was just removed, and `ownerId` is
    /// a persisted read that traps on it. See `PersistentModel+StillInTheStore` and issue 0065.
    private func iOwn(_ edition: Edition) -> InventoryItem? {
        edition.items.first { $0.isStillInTheStore && $0.ownerId == userModel.myUser?._id }
    }

    var body: some View {
        VStack {
            switch viewModel.viewState {
            case .loading:
                // An anchor that resolves over the network opens on the work's own header
                // rather than on a blank screen — see `BookResolvingView`. The others resolve
                // instantly and have nothing to stand in for.
                if let placeholder = viewModel.placeholder {
                    BookResolvingView(placeholder: placeholder)
                } else {
                    ProgressView()
                }
            case .loaded(let edition):
                List {
                    headerSection(edition: edition)
                    otherEditionsSection()
                    communitySection(edition: edition)
                    myCopySection(edition: edition)
                }
                .applyListBackground()
                // Keyed on the works rather than on the edition, because a cached edition can
                // gain a work when the background refresh lands, and that new work needs asking
                // about too.
                .task(id: edition.works.map(\.uri).sorted()) {
                    await enrichGenres(for: edition)
                }
            case .error:
                BookAbsenceView(absence: .failed) { attempt += 1 }
            case .noResult:
                BookAbsenceView(absence: .noEdition)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Popping after a removal is part of the action. The screen used to stay, on the
        // grounds that it stays truthful, but what is left is the record of a book one has just
        // said one no longer owns; the place where the deletion is legible is the list it was
        // deleted from, one book shorter. The snack bar carries the confirmation back.
        .bookActions(
            edition: loadedEdition,
            placement: .toolbar,
            onRemoved: { dismiss() }
        )
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
        .task(id: attempt) {
            await viewModel.load(entityModel: entityModel, modelContext: modelContext)
        }
        .onChange(of: nextEntityDestination) { _, destination in
            if let destination {
                path.append(destination)
                nextEntityDestination = nil
            }
        }
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
                                // The end-to-end scenario's way to the picker. Since Move 3 the
                                // search no longer passes through it, so this row is the only
                                // path left that exercises `WorkEditionPicker` at all.
                                .accessibilityIdentifier("e2e.book.otherEditions")
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    func communitySection(edition: Edition) -> some View {
        // Deleted copies are dropped before `ownerId` is read: the list can still hold the one
        // this screen has just removed. See `PersistentModel+StillInTheStore` and issue 0065.
        let othersItems: [InventoryItem] = edition.items
            .filter { $0.isStillInTheStore && $0.ownerId != userModel.myUser?._id }
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
}
