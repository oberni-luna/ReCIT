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
    let editions: [Edition]
    @Binding var path: NavigationPath

    var body: some View {
        List {
            headerSection
            editionsSection
        }
        .listStyle(.insetGrouped)
        .applyListBackground()
        .navigationTitle("nav.work")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
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
            Menu {
                // Glyphs in the label colour rather than the app's green — see BookDetailView.
                EntityListMenu(entityUri: work.uri, identifier: "e2e.work.addToList")
                    .tint(.foregroundDefault)
            } label: {
                Label("action.more", systemImage: "ellipsis")
            }
            .accessibilityIdentifier("e2e.work.menu")
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
            if editions.isEmpty {
                ProgressView()
            } else {
                ForEach(editions) { edition in
                    let result: SearchResult = .init(
                        id: edition.uri,
                        uri: edition.uri,
                        title: edition.title,
                        description: edition.subtitle,
                        imageUrl: edition.image,
                        score: 0,
                        type: .works
                    )
                    Button {
                        path.append(NavigationDestination.book(anchor: .edition(uri: edition.uri)))
                    } label: {
                        NavigationLink(value: UUID()) {
                            SearchResultCell(result: result)
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
