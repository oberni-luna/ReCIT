//
//  WorkEditionGatewayView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//
//  A work is a text, not a book you can hold — it exists in 1..M editions. So
//  the `.work` destination is a router, not a screen (ADR 0002, Move 2):
//
//  - exactly one edition → render the unified book screen directly, so the user
//    never sees a separate work page (and Back returns straight to the caller);
//  - more than one edition → show `WorkEditionPicker` to choose an edition.
//
//  The count is only known after fetching, so the decision is made here at
//  runtime rather than at the push site.
//

import SwiftUI
import SwiftData

struct WorkEditionGatewayView: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(EditionDuplicatesModel.self) private var editionDuplicatesModel
    @Environment(\.modelContext) private var modelContext

    enum ViewState {
        case loadingWork
        case loadingEditions(work: Work)
        case loaded(work: Work, editions: [Edition])
        case error(error: Error)

        /// The one edition a work has, when the list is in and it is alone.
        var singleEdition: Edition? {
            guard case .loaded(_, let editions) = self, editions.count == 1 else { return nil }
            return editions.first
        }

        var work: Work? {
            switch self {
            case .loadingEditions(let work), .loaded(let work, _):
                work
            case .loadingWork, .error:
                nil
            }
        }

        var isLoadingEditions: Bool {
            if case .loadingEditions = self { true } else { false }
        }
    }

    let workUri: String
    @Binding var path: NavigationPath
    @State private var viewState: ViewState = .loadingWork
    /// Moves each time `load` has written to the editions, for the picker to list them again.
    @State private var revision: Int = 0
    /// The work, its editions and their merge tasks are being fetched again, behind what the
    /// cache already shows.
    @State private var isRefreshing: Bool = false

    var body: some View {
        Group {
            // One branch for the picker, loading or loaded: a branch of its own each time would
            // make it a new view when the editions arrive, and forget the language picked.
            if case .error(let error) = viewState {
                Text("error.with_message \(error.localizedDescription)")
            } else if let edition = viewState.singleEdition {
                BookDetailView(anchor: .edition(uri: edition.uri), path: $path)
            } else if let work = viewState.work {
                WorkEditionPicker(
                    work: work,
                    isLoading: viewState.isLoadingEditions,
                    isRefreshing: isRefreshing,
                    revision: revision,
                    path: $path
                )
            } else {
                ProgressView()
            }
        }
        .task {
            await load()
        }
    }

    /// Shows cached data immediately (if any), then revalidates the work and its
    /// editions in the background, updating the cache in place. When a cached copy
    /// is already on screen, network failures are swallowed so the stale-but-useful
    /// data keeps showing. Mirrors the old WorkDetailView.load.
    @MainActor
    private func load() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let cached: Work? = entityModel.localWork(modelContext: modelContext, uri: workUri)
        if let cached {
            viewState = cached.editions.isEmpty
                ? .loadingEditions(work: cached)
                : .loaded(work: cached, editions: cached.editions)
        }

        do {
            guard let work = try await entityModel.refreshWork(modelContext: modelContext, uri: workUri) else {
                if cached == nil {
                    viewState = .error(error: NSError(domain: "No work", code: 0, userInfo: nil))
                }
                return
            }

            if cached == nil {
                viewState = .loadingEditions(work: work)
            }

            // The editions held are fetched again only once a day: the list shows each one's ISBN,
            // publisher and date, and compares them (PRD 0028), but a work can have thousands.
            // The merge tasks follow the same rhythm, one call per fifty editions.
            let wasStale: Bool = work.editionsNeedRefresh(at: .now)
            try await entityModel.refreshWorkEditions(modelContext: modelContext, work: work)
            viewState = .loaded(work: work, editions: work.editions)
            revision += 1
            if wasStale {
                await editionDuplicatesModel.refreshPendingReports(modelContext: modelContext, work: work)
                revision += 1
            }
        } catch {
            if cached == nil {
                viewState = .error(error: error)
            }
        }
    }
}
