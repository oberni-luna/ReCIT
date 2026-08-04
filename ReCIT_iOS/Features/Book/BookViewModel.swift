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

        do {
            guard let edition = try await entityModel.refreshEdition(modelContext: modelContext, uri: editionUri) else {
                if cached == nil {
                    viewState = .noResult
                }
                return
            }
            viewState = .loaded(edition: edition)
        } catch {
            if cached == nil {
                viewState = .error(error: error)
            }
        }
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
