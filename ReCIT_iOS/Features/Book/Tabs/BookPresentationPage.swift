//
//  BookPresentationPage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// The Fiche livre's Présentation: the summary and its genres, the authors, the other editions,
/// then « Données bibliographiques ». The page the screen opens on.
struct BookPresentationPage: View {
    private let layout: FoldingHeaderPageLayout<BookTab>
    private let edition: Edition
    private let worksWithOtherEditions: [Work]
    private let onEditBibliographicData: () -> Void

    @Binding private var entityDestination: NavigationDestination?

    init(
        _ layout: FoldingHeaderPageLayout<BookTab>,
        edition: Edition,
        worksWithOtherEditions: [Work],
        entityDestination: Binding<NavigationDestination?>,
        onEditBibliographicData: @escaping () -> Void
    ) {
        self.layout = layout
        self.edition = edition
        self.worksWithOtherEditions = worksWithOtherEditions
        _entityDestination = entityDestination
        self.onEditBibliographicData = onEditBibliographicData
    }

    /// The genres to show as tags, read off the `Work` objects themselves rather than taken from
    /// an enrichment call's return value — so the row appears on its own the moment the fetch
    /// writes them, and reappears after any later sync. (ADR 0001, invariant 1.)
    ///
    /// Works are sorted so a two-work edition draws its tags in a stable order; within a work
    /// the stored order is the claims' own, which is the order the labels were resolved in.
    private var genres: [String] {
        var seen: Set<String> = []
        return edition.works
            .sorted(by: { $0.uri < $1.uri })
            .flatMap(\.genres)
            .filter { seen.insert($0).inserted }
    }

    var body: some View {
        FoldingHeaderPage(layout) {
            Group {
                Section {
                    EntitySummaryView(
                        entityUri: edition.uri,
                        otherEntityUri: edition.works.first?.uri,
                        tags: genres
                    )

                    EntityAuthorsView(
                        authors: edition.authors.sorted(by: { $0.name < $1.name }),
                        entityDestination: $entityDestination
                    )
                }

                BookOtherEditionsSection(
                    works: worksWithOtherEditions,
                    entityDestination: $entityDestination
                )

                // Absent for a Wikidata edition, which this app cannot write to.
                if EditionClaims.canEdit(uri: edition.uri) {
                    BookBibliographicDataSection(onEdit: onEditBibliographicData)
                }
            }
            .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
        }
    }
}

#Preview {
    @Previewable @State var destination: NavigationDestination?

    BookPresentationPage(
        .init(
            page: .presentation,
            expandedHeaderHeight: 0,
            headerTop: nil,
            collapse: .init(distance: 0),
            scrollOffset: .init(),
            isFrozen: false
        ),
        edition: .init(uri: "isbn:9782070360024", title: "L'Étranger", lang: "fr", authorNames: []),
        worksWithOtherEditions: [],
        entityDestination: $destination,
        onEditBibliographicData: {}
    )
}
