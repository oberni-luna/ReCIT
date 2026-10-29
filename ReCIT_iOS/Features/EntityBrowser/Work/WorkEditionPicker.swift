//
//  WorkEditionPicker.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//
//  The multi-edition face of a work (ADR 0002, Move 2). When a work has more
//  than one edition, the gateway shows this picker: the work header plus the
//  list of editions to choose from. Picking one pushes the unified book screen.
//

import SwiftUI
import SwiftData

struct WorkEditionPicker: View {
    @State private var nextEntityDestination: NavigationDestination?
    /// The order and the duplicates, worked out off the main actor; `nil` until the first time.
    @State private var listing: EditionListing?
    /// The editions in `listing`'s order, resolved once per listing rather than at every render.
    @State private var orderedEditions: [Edition] = []
    /// Coming back from « Les comparer » lists again: a pair declared different changes no count.
    @State private var appearances: Int = 0
    /// The language picked in the header's menu, `nil` until one is: the phone's is shown until
    /// then, and follows the sync. Forgotten on leaving the screen.
    @State private var chosenLanguage: EditionLanguageFilter?

    let work: Work
    /// The editions are still being fetched: an empty list is not an answer yet.
    let isLoading: Bool
    /// The gateway is fetching the editions again: the ones listed may not be all of them.
    let isRefreshing: Bool
    /// Moves each time the gateway has written to the editions, so the list is worked out again.
    let revision: Int
    @Binding var path: NavigationPath

    /// What the list is worked out again for. `count` follows the observed work: a sync adding
    /// editions, a merge removing one.
    private struct ListingKey: Equatable {
        let count: Int
        let revision: Int
        let appearances: Int
        let language: EditionLanguageFilter?
    }

    var body: some View {
        let duplicates: EditionDuplicates = listing?.duplicates ?? .none
        // An edition a merge removes leaves the list by itself, and is never read once it is
        // gone (PRD 0028).
        let editions: [Edition] = orderedEditions.filter(\.isStillInTheStore)

        List {
            headerSection
            EditionDuplicatesBanner(work: work, duplicates: duplicates) {
                path.append(NavigationDestination.editionDuplicates(workUri: work.uri, language: listing?.language ?? .all))
            }
            editionsSection(editions: editions, duplicates: duplicates)
        }
        .listStyle(.insetGrouped)
        .applyListBackground()
        .readableContentMargins()
        // « Éditions », not « Œuvre »: this screen is now reached only from a book, through
        // « Autres éditions », and the word two moves of ADR 0002 spent hiding has no reason to
        // reappear in a navigation bar. What the screen shows is unchanged.
        .navigationTitle("nav.editions")
        .navigationBarTitleDisplayMode(.inline)
        .workActions(
            workUri: work.uri,
            placement: .toolbar
        )
        .onChange(of: nextEntityDestination) { _, destination in
            if let destination {
                path.append(destination)
                nextEntityDestination = nil
            }
        }
        .onAppear {
            appearances += 1
        }
        .task(id: ListingKey(count: work.editions.count, revision: revision, appearances: appearances, language: chosenLanguage)) {
            await relist()
        }
    }

    /// Reads what the order and the detection need on the main actor, then works the list out
    /// away from it.
    private func relist() async {
        // A sync writes its editions fifty at a time: changes in a row make one listing. A
        // language picked in the menu is shown at once.
        if let listing, chosenLanguage == nil || listing.language == chosenLanguage {
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
        }

        let editions: [Edition] = work.editions.filter(\.isStillInTheStore)
        let listing: EditionListing = await EditionListing.computed(
            entries: editions.map(EditionListing.Entry.init),
            facts: editions.map(EditionFacts.init),
            chosen: chosenLanguage,
            phoneLanguage: Locale.current.language.languageCode?.identifier
        )
        guard Task.isCancelled == false else { return }

        let byUri: [String: Edition] = .init(editions.map { ($0.uri, $0) }, uniquingKeysWith: { first, _ in first })
        orderedEditions = listing.order.compactMap { byUri[$0] }
        self.listing = listing
    }

    @ViewBuilder
    var headerSection: some View {
        Section {
            EntitySummaryView(entityUri: work.uri)

            EntityAuthorsView(
                authors: work.authors.sorted(by: { $0.name < $1.name }),
                entityDestination: $nextEntityDestination
            )
        } header: {
            EntityHeaderView(
                title: work.title,
                subtitle: work.subtitle,
                imageUrl: work.image
            )
        }
    }

    @ViewBuilder
    func editionsSection(editions: [Edition], duplicates: EditionDuplicates) -> some View {
        // The section's own spinner stands for the list while there is none: the header's would
        // say the same thing twice.
        let showsListSpinner: Bool = editions.isEmpty && (isLoading || listing == nil)

        Section {
            if showsListSpinner {
                ProgressView()
            } else {
                ForEach(editions) { edition in
                    Button {
                        path.append(NavigationDestination.book(anchor: .edition(uri: edition.uri)))
                    } label: {
                        NavigationLink(value: UUID()) {
                            EditionCell(edition: edition, tag: duplicates.tags[edition.uri])
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("e2e.workEdition")
                }
            }
        } header: {
            HStack(spacing: .small) {
                Text("work.editions.header \(work.title)")
                    .lineLimit(1)
                    .foregroundStyle(.foregroundSecondary)

                if isRefreshing && showsListSpinner == false {
                    SectionLoadingIndicator()
                }

                Spacer(minLength: 0)

                if let listing {
                    EditionLanguageMenu(
                        options: listing.options,
                        selection: .init(
                            get: { listing.language },
                            set: { chosenLanguage = $0 }
                        )
                    )
                }
            }
            .textStyle(.action200)
        }
    }
}
