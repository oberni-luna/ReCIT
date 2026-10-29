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

    let work: Work
    /// The editions are still being fetched: an empty list is not an answer yet.
    let isLoading: Bool
    /// Moves each time the gateway has written to the editions, so the list is worked out again.
    let revision: Int
    @Binding var path: NavigationPath

    /// What the list is worked out again for. `count` follows the observed work: a sync adding
    /// editions, a merge removing one.
    private struct ListingKey: Equatable {
        let count: Int
        let revision: Int
        let appearances: Int
    }

    var body: some View {
        let duplicates: EditionDuplicates = listing?.duplicates ?? .none
        // An edition a merge removes leaves the list by itself, and is never read once it is
        // gone (PRD 0028).
        let editions: [Edition] = orderedEditions.filter(\.isStillInTheStore)

        List {
            headerSection
            EditionDuplicatesBanner(work: work, duplicates: duplicates) {
                path.append(NavigationDestination.editionDuplicates(workUri: work.uri))
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
        .task(id: ListingKey(count: work.editions.count, revision: revision, appearances: appearances)) {
            await relist()
        }
    }

    /// Reads what the order and the detection need on the main actor, then works the list out
    /// away from it.
    private func relist() async {
        // A sync writes its editions fifty at a time: changes in a row make one listing.
        if listing != nil {
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
        }

        let editions: [Edition] = work.editions.filter(\.isStillInTheStore)
        let listing: EditionListing = await EditionListing.computed(
            entries: editions.map(EditionListing.Entry.init),
            facts: editions.map(EditionFacts.init)
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
        Section {
            if editions.isEmpty && (isLoading || listing == nil) {
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
            Text("work.editions.header \(work.title)")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
    }
}
