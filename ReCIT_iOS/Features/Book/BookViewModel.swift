//
//  BookViewModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation
import SwiftData

/// Drives the unified book screen (ADR 0002, Move 1 / P1). It resolves a
/// `BookAnchor` to an `Edition` — cache-first, then background revalidation that
/// upserts in place — and exposes the predicate the view uses to query the
/// current user's copies of that edition for the "Ton exemplaire" overlay.
///
/// Behaviour deliberately mirrors `EditionDetailView.loadEdition` so the two
/// screens stay identical while the migration is in flight.
@MainActor
@Observable
final class BookViewModel {
    enum ViewState {
        case loading
        case loaded(edition: Edition)
        case error(error: Error)
        case noResult
    }

    private let anchor: BookAnchor

    private(set) var viewState: ViewState = .loading

    /// The works this edition is based on that have *other* editions besides this
    /// one — i.e. the ones worth offering an "other editions" link for. Populated
    /// in the background after the edition loads; empty until then and whenever no
    /// underlying work has siblings.
    private(set) var worksWithOtherEditions: [Work] = []

    init(anchor: BookAnchor) {
        self.anchor = anchor
    }

    /// The edition URI this screen presents, resolved from the anchor.
    var editionUri: String? {
        anchor.editionUri
    }

    /// Shows the cached edition immediately (if any), then revalidates it in the
    /// background and upserts in place. When a cached copy is already on screen,
    /// network failures are swallowed so the stale-but-useful data keeps showing.
    /// (ADR 0001, invariants 1 & 2)
    func load(
        entityModel: EntityModel,
        modelContext: ModelContext
    ) async {
        guard let editionUri else {
            viewState = .noResult
            return
        }

        let cached: Edition? = entityModel.localEdition(modelContext: modelContext, uri: editionUri)
        if let cached {
            viewState = .loaded(edition: cached)
        }

        var resolved: Edition? = cached
        do {
            if let edition = try await entityModel.refreshEdition(modelContext: modelContext, uri: editionUri) {
                viewState = .loaded(edition: edition)
                resolved = edition
            } else if cached == nil {
                viewState = .noResult
            }
        } catch {
            if cached == nil {
                viewState = .error(error: error)
            }
        }

        if let resolved {
            await loadOtherEditions(for: resolved, entityModel: entityModel, modelContext: modelContext)
        }
    }

    /// For each work the edition is based on, resolves whether that work has
    /// editions beyond this one and records the ones that do. Runs after the
    /// edition is on screen; mutating `worksWithOtherEditions` updates the view
    /// reactively. Failures are swallowed — a missing link is better than a stuck
    /// screen.
    private func loadOtherEditions(
        for edition: Edition,
        entityModel: EntityModel,
        modelContext: ModelContext
    ) async {
        var result: [Work] = []
        for work in edition.works {
            let editions: [Edition] = (try? await entityModel.getWorkEditions(modelContext: modelContext, work: work)) ?? []
            if editions.count > 1 {
                result.append(work)
            }
        }
        worksWithOtherEditions = result
    }

    /// Predicate for the view's `@Query` of the current user's copies of an
    /// edition. Kept static and pure so it is unit-testable against an in-memory
    /// store, independent of any live view. (ADR 0002 — "Ton exemplaire")
    static func ownedItemsPredicate(
        editionUri: String,
        ownerId: String
    ) -> Predicate<InventoryItem> {
        #Predicate { item in
            item.ownerId == ownerId && item.edition?.uri == editionUri
        }
    }
}
