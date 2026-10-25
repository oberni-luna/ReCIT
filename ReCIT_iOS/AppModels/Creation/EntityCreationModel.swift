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
//  It also changes an edition that exists — its title, its subtitle, its cover — from the
//  book screen's « Modifier ». Same open database, same reasons not to be optimistic.
//
//  See PRD 0015.
//

import Foundation
import SwiftData

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

    /// The works a search proposed, each completed by what tells it apart: who wrote it, and
    /// when.
    ///
    /// `/api/search` answers a label, a description and a cover — not the two facts a reader
    /// recognises a book by. One `by-uris` call with `relatives=wdt:P50` brings both: the works'
    /// claims and, in the same envelope, their authors' labels. Public, so it goes cookieless
    /// like the ISBN lookup. When it fails the search's own description stands in: a candidate
    /// is still worth showing without its byline, and a search is not a place for an error.
    func describeWorks(_ results: [SearchResult]) async -> [WorkCandidate] {
        guard results.isEmpty == false else { return [] }

        let uris: String = results.map(\.uri).joined(separator: "|")
        let response: WorkSummariesDTO? = try? await publicAPIService.fetchData(
            fromEndpoint: "/api/entities/by-uris?uris=\(uris)&attributes=labels|claims&lang=fr&relatives=wdt:P50",
            debug: false
        )

        return WorkCandidate.candidates(from: results, entities: response?.entities ?? [:])
    }

    /// Sends the cover the reader chose, and answers the url inventaire.io filed it under —
    /// or `nil`, which is not a failure worth stopping for.
    ///
    /// The image is an ornament; the book is the point. `enrich` already goes looking for a
    /// cover from the ISBN, so an upload that does not land costs a picture and nothing else.
    /// That is why this answers an optional instead of throwing: the caller has no decision to
    /// make about it.
    ///
    /// The url is made **absolute**. The upload answers a path, `/img/entities/…`, and the
    /// edition seed's `image` must be a url the server can fetch: `resolve` refuses anything
    /// else (`isUrl` in `sanitize_seed.ts`) — the whole entry, not just the picture.
    func uploadCover(imageData: Data) async -> String? {
        let path: String? = try? await apiService.upload(
            imageData: imageData,
            fileName: "cover.jpg",
            // The server indexes what it answers by the form field name it was given, so this
            // string is also the key the url comes back under.
            fieldName: "cover",
            container: "entities",
            debug: false
        )

        return apiService.absoluteImageUrl(path)
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

    // MARK: - Changing an edition

    /// What inventaire.io holds about the edition, read fresh to open « Modifier l'édition »:
    /// the values the form starts from, and the ones each change has to name as replaced.
    ///
    /// Public, so cookieless. Throws when the answer holds no `inv:` edition — a Wikidata one,
    /// or nothing at all: there is then nothing the form could send.
    func editableEdition(uri: String) async throws -> EditionClaims {
        let response: EditableEditionsDTO? = try await publicAPIService.fetchData(
            fromEndpoint: "/api/entities/by-uris?uris=\(uri)&attributes=info|claims",
            debug: false
        )

        guard let claims = response?.entities.values.lazy.compactMap(EditionClaims.init(dto:)).first else {
            throw NetworkError.badResponse
        }

        return claims
    }

    /// Where the picture filed under `hash` is served from.
    func coverURL(hash: String) -> URL? {
        apiService.absoluteImageUrl(EntityImageHash.path(of: hash)).flatMap(URL.init(string:))
    }

    /// Sends what the form changed — the picture first, when there is a new one, then one
    /// `update-claim` per claim — and answers the edit with everything landed.
    ///
    /// Unlike a new book's, a new cover is not an ornament here: it may be the whole change the
    /// reader asked for, so an upload that does not land is a failure like any other.
    ///
    /// Throws `EditionSaveFailure`, which carries the edit as far as it got: the claims that
    /// landed have moved into its `original`, and are not sent again.
    func saveEdition(_ edit: EditionEdit) async throws -> EditionEdit {
        var edit: EditionEdit = edit

        do {
            if let imageData = edit.coverToUpload {
                let path: String? = try await apiService.upload(
                    imageData: imageData,
                    fileName: "cover.jpg",
                    fieldName: "cover",
                    container: "entities",
                    debug: false
                )
                guard let hash = EntityImageHash.from(path) else { throw NetworkError.badResponse }
                edit.uploadedCoverHash = hash
            }

            for update in edit.claimUpdates {
                let _: OkStatusDTO? = try await apiService.send(
                    toEndpoint: "/api/entities/update-claim",
                    method: "PUT",
                    payload: update,
                    debug: true
                )
                edit.landed(update)
            }

            return edit
        } catch {
            throw EditionSaveFailure(edit: edit, underlying: error)
        }
    }

    /// Writes into the local edition what moved on the server between `before` and `after`, so
    /// the book screen shows it at once.
    ///
    /// After the server has answered, never before: the local store is a cache of inventaire.io,
    /// and this change is not optimistic. Written directly rather than read back, because a read
    /// straight after a write can be served from a cache the write has not reached yet. Only
    /// what moved: the local image may come from somewhere other than `invp:P2`, and a cover
    /// nobody touched must not be cleared for having no hash.
    func apply(
        _ after: EditionClaims,
        since before: EditionClaims,
        to edition: Edition,
        modelContext: ModelContext
    ) {
        guard edition.isStillInTheStore, after != before else { return }

        if after.title != before.title, after.title.isEmpty == false {
            edition.title = after.title
        }
        if after.subtitle != before.subtitle {
            edition.subtitle = after.subtitle
        }
        if after.coverHash != before.coverHash {
            edition.image = after.coverHash.flatMap { apiService.absoluteImageUrl(EntityImageHash.path(of: $0)) }
        }
        try? modelContext.save()
    }
}
