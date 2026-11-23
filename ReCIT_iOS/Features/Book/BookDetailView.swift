//
//  BookDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import SwiftUI
import SwiftData

/// The Fiche livre, anchored on an edition, shaped like a reader's profile: a header held at the
/// top — the cover, the title, the authors and the subtitle, and the Présentation | Mon exemplaire
/// | Dans le réseau tabs — that folds into the navigation bar as the page scrolls, and never stays
/// half folded. Each tab is a page of its own in a `FoldingHeaderPager`, changed by a swipe as
/// well as by its name. It always opens on Présentation.
struct BookDetailView: View {
    @State private var viewModel: BookViewModel
    @State private var nextEntityDestination: NavigationDestination?
    @State private var borrowFromItem: InventoryItem?
    /// The edition « Modifier » opened the form of, while the sheet is up.
    @State private var editedEdition: Edition?
    /// What « Ajouter à une liste » asks to create, under Mon exemplaire.
    @State private var creationRequest: ContainerCreationRequest?
    /// How many times this screen has been asked to load. Bumped by « Réessayer », and the
    /// `.task` key — which is how a retry re-runs a call that nothing else about the screen has
    /// changed. One way in, so loading, the book, the two absences and the failure are decided
    /// in one place. Same shape as `SearchContent`'s.
    @State private var attempt: Int = 0
    @State private var tab: BookTab = .presentation
    /// The header's title at rest and the line under it, measured: how far the header folds
    /// depends on how many lines they take.
    @State private var titleHeight: CGFloat = 0
    @State private var bylineHeight: CGFloat = 0

    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize
    @Environment(EntityModel.self) private var entityModel: EntityModel
    @Environment(UserModel.self) private var userModel: UserModel
    @Environment(GenreEnrichmentModel.self) private var genreEnrichmentModel: GenreEnrichmentModel

    init(
        anchor: BookAnchor,
        path: Binding<NavigationPath>
    ) {
        _viewModel = State(initialValue: .init(anchor: anchor))
        _path = path
    }

    private var loadedEdition: Edition? {
        if case let .loaded(edition) = viewModel.viewState {
            return edition
        }
        return nil
    }

    private var metrics: BookHeaderMetrics {
        .init(
            dynamicTypeSize: dynamicTypeSize,
            titleHeight: titleHeight,
            bylineHeight: bylineHeight
        )
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
            case let .loaded(edition):
                pages(edition)
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
            TransactionRequestSheet(item)
        }
        .sheet(item: $editedEdition) { edition in
            EditEditionFlowView(edition: edition)
        }
        .containerCreationSheet($creationRequest)
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

    /// The three pages side by side, a swipe or a tab's name apart, under the header.
    private func pages(_ edition: Edition) -> some View {
        FoldingHeaderPager(
            selection: $tab,
            tabs: BookTab.allCases,
            collapse: metrics.collapse
        ) { scrollOffset in
            BookHeader(
                edition: edition,
                tab: $tab,
                tabs: BookTab.allCases,
                myUserId: userModel.myUser?._id,
                metrics: metrics,
                scrollOffset: scrollOffset,
                onMeasureTitle: { titleHeight = $0 },
                onMeasureByline: { bylineHeight = $0 }
            )
        } page: { layout in
            page(layout, edition: edition)
        }
    }

    @ViewBuilder
    private func page(
        _ layout: FoldingHeaderPageLayout<BookTab>,
        edition: Edition
    ) -> some View {
        switch layout.page {
        case .presentation:
            BookPresentationPage(
                layout,
                edition: edition,
                worksWithOtherEditions: viewModel.worksWithOtherEditions,
                entityDestination: $nextEntityDestination,
                onEditBibliographicData: { editedEdition = edition }
            )
        case .myCopy:
            BookMyCopyPage(
                layout,
                edition: edition,
                creationRequest: $creationRequest
            )
        case .network:
            BookNetworkPage(
                layout,
                edition: edition,
                entityDestination: $nextEntityDestination,
                onRequest: { borrowFromItem = $0 }
            )
        }
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
