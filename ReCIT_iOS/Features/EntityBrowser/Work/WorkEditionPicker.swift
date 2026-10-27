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

    let work: Work
    /// The editions are still being fetched: an empty list is not an answer yet.
    let isLoading: Bool
    @Binding var path: NavigationPath

    /// Read off the observed work rather than handed in: an edition a merge removes leaves the
    /// list by itself, and is never read once it is gone (PRD 0028).
    private var editions: [Edition] {
        work.editions.sorted(by: Self.listOrder)
    }

    var body: some View {
        List {
            headerSection
            editionsSection
        }
        .listStyle(.insetGrouped)
        .applyListBackground()
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
    var editionsSection: some View {
        Section {
            if editions.isEmpty && isLoading {
                ProgressView()
            } else {
                ForEach(editions) { edition in
                    Button {
                        path.append(NavigationDestination.book(anchor: .edition(uri: edition.uri)))
                    } label: {
                        NavigationLink(value: UUID()) {
                            EditionCell(edition: edition)
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

    /// Oldest first, as a publication history reads; an edition without a date last; then by
    /// title, then by uri, so the order never moves between two visits.
    static func listOrder(_ lhs: Edition, _ rhs: Edition) -> Bool {
        switch (lhs.publicationYear, rhs.publicationYear) {
        case let (left?, right?) where left != right:
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            let titles: ComparisonResult = lhs.title.localizedStandardCompare(rhs.title)
            return titles == .orderedSame ? lhs.uri < rhs.uri : titles == .orderedAscending
        }
    }
}
