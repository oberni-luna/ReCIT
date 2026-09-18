//
//  EntityCreationModel.swift
//  ReCIT_iOS
//
//  Writing into inventaire.io's open database: the one thing this app does that is not about
//  the reader's own shelves.
//
//  Its own model rather than a method on `EntityModel`, which reads and refreshes entities.
//  This one publishes, and publishing fails differently: what is at stake is not a stale cache
//  but a duplicate nobody can undo from a phone.
//
//  **Nothing here is optimistic.** ADR 0001 makes writes land locally first and reconcile in
//  the background; the batch scanner already departs from that for its adds, because the
//  confirmation *is* the feature. Here the reason is stronger still: an optimistic publication
//  that failed would leave the reader believing they had contributed, and an optimistic one
//  that half-succeeded would leave a work without its edition on a public website. So the call
//  is awaited, and the form stays open until the server has spoken.
//
//  See PRD 0015.
//

import Foundation

@MainActor
@Observable
final class EntityCreationModel {
    private let apiService: APIServicing

    init(apiService: APIServicing) {
        self.apiService = apiService
    }

    /// Creates the edition — and, as needed, its work and its author — and answers with the
    /// **canonical** uri of the edition.
    ///
    /// Returning an identity rather than something to display: the caller needs it to create
    /// the inventory item, which is what the reader scanned the book for. Views still render
    /// from SwiftData, as ADR 0001 asks.
    func createEdition(draft: NewBookDraft) async throws -> String {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(for: draft, create: true)

        let response: EntityResolveResponse? = try await apiService.send(
            toEndpoint: "/api/entities/resolve",
            method: "POST",
            payload: request,
            debug: true
        )

        guard let uri = response?.editionUri else {
            // The server answered without an edition uri. Rare, and not something to paper
            // over: the item that would be created from a guessed uri is worse than no item.
            throw NetworkError.badResponse
        }

        return uri
    }
}
