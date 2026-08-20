//
//  EntitySummaryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//
//  The Figma `Row / Summary` component (`38:201`), which since issue 0035 also carries a `meta`
//  frame of tinted tags under the body.
//
//  One departure from that component, on purpose. In Figma the meta frame only exists *inside* a
//  summary row, so a work Wikipedia knows nothing about would have nowhere to draw its tags —
//  and on this library that is the common case, not the edge one. Tags nested inside the summary
//  would then vanish for a reason with nothing to do with tags. So the row draws the summary when
//  there is one, the tags when there are any, and collapses entirely only when there is neither.
//

import SwiftUI
import SwiftData

struct EntitySummaryView: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loading
        case loaded(data: WpExtract)
        case error(error: Error)
        case empty
    }
    @State private var viewState: ViewState = .loading
    @State private var showMore: Bool = false

    let entityUri: String
    let otherEntityUri: String?

    /// Meta tags drawn under the body. Passed in rather than resolved here, so the row stays
    /// ignorant of what they mean — the book screen fills them with the work's genres, read
    /// straight from the store.
    let tags: [String]

    init(
        entityUri: String,
        otherEntityUri: String? = nil,
        tags: [String] = []
    ) {
        self.entityUri = entityUri
        self.otherEntityUri = otherEntityUri
        self.tags = tags
    }

    /// Nothing to draw at all: no extract, and no tags either. Stated explicitly so the list row
    /// collapses instead of leaving an empty inset behind — which is what a `VStack` with no
    /// visible children would do.
    private var isEmpty: Bool {
        guard tags.isEmpty else { return false }
        if case .empty = viewState { return true }
        return false
    }

    var body: some View {
        Group {
            if isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: .xSmall) {
                    switch viewState {
                    case .loading:
                        ProgressView()
                    case .loaded(data: let data):
                        Text(data.content)
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                            .lineLimit(3)
                            .withLabel(label: String(localized: "entity.summary.label"))
                            .onTapGesture {
                                showMore = true
                            }
                            .sheet(isPresented: $showMore) {
                                ScrollView {
                                    Text(data.content)
                                        .textStyle(.content400)
                                        .foregroundStyle(.foregroundDefault)
                                        .padding(.all, .large)
                                }
                                .presentationDetents([.medium, .large])
                            }
                    case .error(error: let error):
                        Text("error.with_message \(error.localizedDescription)")
                    case .empty:
                        EmptyView()
                    }

                    // Outside the switch on purpose: the tags belong to the row, not to the
                    // extract's fetch, so they survive it loading, failing or finding nothing.
                    if !tags.isEmpty {
                        EntityMetaTagsView(tags: tags)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await fetchExtract()
            }
        }
    }

    @MainActor
    private func fetchExtract() async {
        do {
            if let extract = try await entityModel.getOrFetchExtract(forUri: entityUri, modelContext: modelContext) {
                viewState = .loaded(data: extract)
            } else {
                if let entityUri = otherEntityUri,
                   let extract = try await entityModel.getOrFetchExtract(forUri: entityUri, modelContext: modelContext) {
                    viewState = .loaded(data: extract)
                } else {
                    viewState = .empty
                }
            }
        } catch {
            viewState = .error(error: error)
        }
    }

    enum EntityLoaderError: Error {
        case notFound
        case undecodable
    }
}

#Preview {
//    EntitySummaryView()
}
