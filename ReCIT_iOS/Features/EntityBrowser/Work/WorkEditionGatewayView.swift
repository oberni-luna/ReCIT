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
    @Environment(\.modelContext) private var modelContext

    enum ViewState {
        case loadingWork
        case loadingEditions(work: Work)
        case loaded(work: Work, editions: [Edition])
        case error(error: Error)
    }

    let workUri: String
    @Binding var path: NavigationPath
    @State private var viewState: ViewState = .loadingWork

    var body: some View {
        Group {
            switch viewState {
            case .loadingWork:
                ProgressView()
            case .loadingEditions(let work):
                WorkEditionPicker(work: work, editions: [], path: $path)
            case .loaded(let work, let editions):
                if editions.count == 1, let edition = editions.first {
                    BookDetailView(anchor: .edition(uri: edition.uri), path: $path)
                } else {
                    WorkEditionPicker(work: work, editions: editions, path: $path)
                }
            case .error(let error):
                Text("error.with_message \(error.localizedDescription)")
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

            let editions: [Edition] = try await entityModel.getWorkEditions(modelContext: modelContext, work: work) ?? work.editions
            viewState = .loaded(work: work, editions: editions)
        } catch {
            if cached == nil {
                viewState = .error(error: error)
            }
        }
    }
}
