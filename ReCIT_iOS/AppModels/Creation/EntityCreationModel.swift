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
    /// The cookieless service, for the one call here that is made about a book rather than
    /// about a reader. `GET /api/data/isbn` is public; sending a session to it would have
    /// inventaire.io hand one back for nothing (issue 0068).
    private let publicAPIService: APIServicing

    init(apiService: APIServicing, publicAPIService: APIServicing) {
        self.apiService = apiService
        self.publicAPIService = publicAPIService
    }

    /// What the ISBN says about the language of the book.
    ///
    /// The registration group of an ISBN is handed out by language area — `978-2` is the
    /// French-language group — so this is a fact, not a guess, and it saves the form a
    /// question. Answers `nil` when the server does not know, when the call fails, or when the
    /// group has no language: the edition is then published **without** a language claim. A
    /// wrong language on a public edition reads, ever after, as something somebody checked.
    func editionLanguage(isbn: String) async -> EditionLanguage? {
        let normalized: String = isbn.uppercased().filter { $0.isNumber || $0 == "X" }
        guard normalized.isEmpty == false else { return nil }

        let facts: IsbnFactsDTO? = try? await publicAPIService.fetchData(
            fromEndpoint: "/api/data/isbn?isbn=\(normalized)",
            debug: false
        )

        guard let uri = facts?.groupLangUri, let code = facts?.groupLang else { return nil }

        return .init(uri: uri, code: code)
    }

    /// Sends the cover the reader photographed, and answers the url inventaire.io filed it
    /// under — or `nil`, which is not a failure worth stopping for.
    ///
    /// The image is an ornament; the book is the point. `enrich` already goes looking for a
    /// cover from the ISBN, so an upload that does not land costs a picture and nothing else.
    /// That is why this answers an optional instead of throwing: the caller has no decision to
    /// make about it.
    func uploadCover(imageData: Data) async -> String? {
        try? await apiService.upload(
            imageData: imageData,
            fileName: "cover.jpg",
            // The server indexes what it answers by the form field name it was given, so this
            // string is also the key the url comes back under.
            fieldName: "cover",
            container: "entities",
            debug: false
        )
    }

    /// Asks inventaire.io what it already knows about this book, **without writing anything**.
    ///
    /// The answer that matters is the work: *La Main gauche de la nuit* exists, and it is this
    /// edition of it that is missing. Knowing that before publishing is what lets the reader
    /// add an edition to a work instead of creating a second work of the same name — the kind
    /// of duplicate that splits a bibliography and needs merge rights to repair.
    ///
    /// Answers the uri of a work the server **resolved**, never one it says it would create.
    /// A call that fails answers `nil`: the question is then not put, the publication goes
    /// ahead, and the server dedupes on its own side as best it can. A reconnaissance pass is
    /// worth a screen, not a blocked contribution.
    func recogniseWork(draft: NewBookDraft) async -> String? {
        let request: EntityResolveRequest = ResolveRequestBuilder.request(for: draft, create: false)

        let response: EntityResolveResponse? = try? await apiService.send(
            toEndpoint: "/api/entities/resolve",
            method: "POST",
            payload: request,
            debug: false
        )

        return response?.resolvedWorkUri
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
