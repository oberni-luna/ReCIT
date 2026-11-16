//
//  EntitySync.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/11/2026.
//

import Foundation
import SwiftData

/// The works and authors a sync files books under, fetched from inventaire.io and upserted off
/// the main actor (ADR 0009).
///
/// It runs on the executor of the sync that makes it, and so writes that sync's context: the
/// works it upserts are there for the sync to link its items to, and are saved with the sync's
/// own saves — never on their own.
actor EntitySync: ModelActor {
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    private let apiService: any APIServicing

    init(
        modelExecutor: any ModelExecutor,
        modelContainer: ModelContainer,
        apiService: any APIServicing
    ) {
        self.modelExecutor = modelExecutor
        self.modelContainer = modelContainer
        self.apiService = apiService
    }

    /// Fetches the works under `uris` and merges them into the store, adding to each the author
    /// under `authorURI` — none when the inventory does not know who wrote them.
    ///
    /// Upserted, never built: a work made afresh on every sync used to empty the stored one's
    /// genres and preferred edition (issue 0067). A work under two authors arrives under each,
    /// and keeps both.
    func upsertWorks(uris: [String], authorURI: String?) async throws {
        let authors: [Author] = if let authorURI {
            try await authors(uris: [authorURI])
        } else {
            []
        }
        for dto in try await apiService.entities(uris: uris) {
            try modelContext.upsertWork(dto, authors: authors, apiService: apiService)
        }
    }

    /// The authors under `uris`: those the store holds with a name, then the others, fetched.
    ///
    /// A nameless author is fetched again: it was stored before `EntityLabel` read the `mul`
    /// label, and the store alone would keep it nameless for good. Fetched ones are upserted, as
    /// the server may answer a uri with the entity it now redirects to, which the store can hold.
    private func authors(uris: [String]) async throws -> [Author] {
        let held: [Author] = try modelContext
            .fetch(FetchDescriptor<Author>(predicate: #Predicate { uris.contains($0.uri) }))
            .filter { $0.name.isEmpty == false }
        let heldURIs: Set<String> = .init(held.map(\.uri))
        let missing: [String] = uris.filter { heldURIs.contains($0) == false }
        guard missing.isEmpty == false else { return held }

        let fetched: [EntityResultDTO] = try await apiService.entities(uris: missing)
        return held + (try modelContext.upsertAuthors(fetched, apiService: apiService))
    }
}
