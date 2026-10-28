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
//  It also changes an edition that exists — everything inventaire.io accepts on it, the works
//  it is an edition of, their titles and authors — from the book screen's « Données
//  bibliographiques ». Same open database, same reasons not to be optimistic. And it changes
//  a work or a person on their own, from « Modifier l'œuvre » and « Modifier l'auteur·ice »
//  (PRD 0030), each saved by its own « Enregistrer ».
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

    /// Creates the publishers, collections and people a new edition names that inventaire.io
    /// does not have — publishers first, a collection under its publisher — before `resolve` names
    /// them by uri. Each one created is handed to `onCreated` as it lands, so that a failure
    /// halfway keeps what exists and a retry does not create it twice.
    func createPendingEntities(
        of properties: EditionProperties,
        language: String,
        onCreated: (UUID, String) -> Void
    ) async throws {
        var properties: EditionProperties = properties
        while let pending = properties.pendingEntities.first(where: {
            EntityCreationKind(for: $0.property, publisherUri: properties.publisherUri) != nil
        }), let kind = EntityCreationKind(for: pending.property, publisherUri: properties.publisherUri) {
            let uri: String = try await createEntity(label: pending.entity.trimmedLabel, language: language, kind: kind)
            properties.entityCreated(id: pending.entity.id, uri: uri)
            onCreated(pending.entity.id, uri)
        }
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
    /// The publishers, collections and people its claims name come in the same envelope, asked
    /// as relatives, with their labels. Languages are not relatives `by-uris` knows: those, and
    /// anything else left unnamed, are asked for in a second call — and keep their uri as a name
    /// when it fails, which is ugly but not wrong.
    ///
    /// Public, so cookieless. Throws when the answer holds no `inv:` edition — a Wikidata one,
    /// or nothing at all: there is then nothing the form could send.
    func editableEdition(uri: String) async throws -> EditionClaims {
        let response: EditableEditionsDTO? = try await publicAPIService.fetchData(
            fromEndpoint: "/api/entities/by-uris?uris=\(uri)&attributes=info|claims|labels&lang=fr&relatives=\(Self.namedRelatives)",
            debug: false
        )

        guard let entities = response?.entities,
              let edition = entities[response?.redirects?[uri] ?? uri]
                ?? entities.values.first(where: { EditionClaims(dto: $0) != nil }),
              let unnamed = EditionClaims(dto: edition) else {
            throw NetworkError.badResponse
        }

        var labels: [String: String] = entities.compactMapValues(\.displayName)
        let missing: [String] = unnamed.properties.entityUris.filter { labels[$0] == nil }
        if missing.isEmpty == false {
            let named: EditableEditionsDTO? = try? await publicAPIService.fetchData(
                fromEndpoint: "/api/entities/by-uris?uris=\(missing.joined(separator: "|"))&attributes=labels&lang=fr",
                debug: false
            )
            labels.merge(named?.entities.compactMapValues(\.displayName) ?? [:]) { known, _ in known }
        }

        return EditionClaims(dto: edition, labels: labels) ?? unnamed
    }

    /// The claims of an edition whose values `by-uris` can bring along, with their labels.
    private static let namedRelatives: String = EditionProperty.all
        .filter { $0.searchType != nil && $0.searchType != .languages }
        .map(\.uri)
        .joined(separator: "|")

    /// Where the picture filed under `hash` is served from.
    func coverURL(hash: String) -> URL? {
        apiService.absoluteImageUrl(EntityImageHash.path(of: hash)).flatMap(URL.init(string:))
    }

    /// The works an edition is an edition of, in the order asked, with their authors' names and
    /// uris — what the form shows, and what « Modifier l'œuvre » changes. Public, so cookieless;
    /// the authors come in the same envelope, asked as relatives. A work the answer does not hold
    /// is left out rather than failing the whole form.
    func describeWorks(uris: [String]) async throws -> [EditionWork] {
        guard uris.isEmpty == false else { return [] }

        let response: WorkSummariesDTO? = try await publicAPIService.fetchData(
            fromEndpoint: "/api/entities/by-uris?uris=\(uris.joined(separator: "|"))&attributes=labels|claims&lang=fr&relatives=wdt:P50",
            debug: false
        )

        guard let entities = response?.entities else { throw NetworkError.badResponse }

        return uris.compactMap { uri in
            guard let work = entities[uri] ?? entities.values.first(where: { $0.uri == uri }) else { return nil }

            let authors: [NewBookAuthor] = work.values(of: .author).compactMap { authorUri in
                guard let name = entities[authorUri]?.label else { return nil }
                return .init(name: name, uri: authorUri)
            }

            return .init(
                uri: uri,
                title: work.label ?? "",
                authors: authors,
                titleLanguage: EntityLabel.language(of: work.labels)
            )
        }
    }

    /// Runs what the form changed, one request at a time in the order `EditionEdit.nextStep`
    /// gives — the picture, the authors, works, publishers, collections and people that do not
    /// exist yet, then the claims, then the works' new titles — and answers the edit with
    /// everything landed.
    ///
    /// Unlike a new book's, a new cover is not an ornament here: it may be the whole change the
    /// reader asked for, so an upload that does not land is a failure like any other.
    ///
    /// Throws `EditionSaveFailure`, which carries the edit as far as it got: what landed has
    /// moved into it, and is neither sent nor created again.
    func saveEdition(_ edit: EditionEdit) async throws -> EditionEdit {
        var edit: EditionEdit = edit
        // Every step lands or throws; a step that did neither would loop for ever.
        var budget: Int = 100

        do {
            while let step = edit.nextStep {
                budget -= 1
                guard budget > 0 else { throw NetworkError.badResponse }

                switch step {
                case .uploadCover(let imageData):
                    let path: String? = try await apiService.upload(
                        imageData: imageData,
                        fileName: "cover.jpg",
                        fieldName: "cover",
                        container: "entities",
                        debug: false
                    )
                    guard let hash = EntityImageHash.from(path) else { throw NetworkError.badResponse }
                    edit.coverUploaded(hash: hash)

                case .createAuthor(let id, let label, let language):
                    let uri: String = try await createEntity(
                        label: label,
                        language: language,
                        claims: [WikidataProperty.instanceOf.rawValue: [Self.human]]
                    )
                    edit.authorCreated(id: id, uri: uri)

                case .createWork(let id, let label, let language, let authorUris):
                    let uri: String = try await createEntity(
                        label: label,
                        language: language,
                        claims: [
                            WikidataProperty.instanceOf.rawValue: [Self.literaryWork],
                            EditableClaimProperty.author.rawValue: authorUris
                        ]
                    )
                    edit.workCreated(id: id, uri: uri)

                case .createEntity(let id, let label, let language, let kind):
                    let uri: String = try await createEntity(label: label, language: language, kind: kind)
                    edit.entityCreated(id: id, uri: uri)

                case .claim(let update):
                    let _: OkStatusDTO? = try await apiService.send(
                        toEndpoint: "/api/entities/update-claim",
                        method: "PUT",
                        payload: update,
                        debug: true
                    )
                    edit.landed(update)

                case .label(let update):
                    let _: OkStatusDTO? = try await apiService.send(
                        toEndpoint: "/api/entities/update-label",
                        method: "PUT",
                        payload: update,
                        debug: true
                    )
                    edit.landed(update)
                }
            }

            return edit
        } catch {
            throw EditionSaveFailure(edit: edit, underlying: error)
        }
    }

    // MARK: - Changing a work or a person

    /// What inventaire.io holds about a work or a person, read fresh to open « Modifier l'œuvre »
    /// or « Modifier l'auteur·ice »: its labels and every property of its catalogue, the
    /// entities they name labelled by a second call. `relatives` is not asked: it does not know
    /// every property a work or a person can name. A name that does not come keeps the uri.
    ///
    /// Public, so cookieless. Throws when the answer holds neither a work nor a person.
    func editableEntity(uri: String) async throws -> EntityEdit {
        let response: EditableEditionsDTO? = try await publicAPIService.fetchData(
            fromEndpoint: "/api/entities/by-uris?uris=\(uri)&attributes=info|claims|labels&lang=fr",
            debug: false
        )

        guard let entities = response?.entities,
              let entity = entities[response?.redirects?[uri] ?? uri] ?? entities.values.first,
              let catalogue = EditionProperty.Catalogue(entityType: entity.type),
              catalogue != .edition else {
            throw NetworkError.badResponse
        }

        let claims: [String: [ClaimValue]] = entity.claims ?? [:]
        let unnamed: EditionProperties = .init(claims: claims, labels: [:], catalogue: catalogue)
        var labels: [String: String] = [:]
        if unnamed.entityUris.isEmpty == false {
            let named: EditableEditionsDTO? = try? await publicAPIService.fetchData(
                fromEndpoint: "/api/entities/by-uris?uris=\(Array(Set(unnamed.entityUris)).sorted().joined(separator: "|"))&attributes=labels&lang=fr",
                debug: false
            )
            labels = named?.entities.compactMapValues(\.displayName) ?? [:]
        }

        return .init(
            uri: entity.uri,
            labels: entity.labels ?? [:],
            properties: .init(claims: claims, labels: labels, catalogue: catalogue),
            originalLanguage: entity.originalLang
        )
    }

    /// Runs what « Modifier l'œuvre » or « Modifier l'auteur·ice » changed, one request at a
    /// time in the order `EntityEdit.nextStep` gives — the people to create, the claims, the
    /// labels — and answers the edit with everything landed.
    ///
    /// Throws `EntitySaveFailure`, which carries the edit as far as it got.
    func saveEntity(_ edit: EntityEdit) async throws -> EntityEdit {
        var edit: EntityEdit = edit
        // Every step lands or throws; a step that did neither would loop for ever.
        var budget: Int = 200

        do {
            while let step = edit.nextStep {
                budget -= 1
                guard budget > 0 else { throw NetworkError.badResponse }

                switch step {
                case .createEntity(let id, let label, let language, let kind):
                    let uri: String = try await createEntity(label: label, language: language, kind: kind)
                    edit.entityCreated(id: id, uri: uri)

                case .claim(let update):
                    let _: OkStatusDTO? = try await apiService.send(
                        toEndpoint: "/api/entities/update-claim",
                        method: "PUT",
                        payload: update,
                        debug: true
                    )
                    edit.landed(update)

                case .label(let update):
                    let _: OkStatusDTO? = try await apiService.send(
                        toEndpoint: "/api/entities/update-label",
                        method: "PUT",
                        payload: update,
                        debug: true
                    )
                    edit.landed(update)

                case .uploadCover, .createAuthor, .createWork:
                    // Not steps of a work or a person: `EntityEdit` never lists them.
                    throw NetworkError.badResponse
                }
            }

            return edit
        } catch {
            throw EntitySaveFailure(edit: edit, underlying: error)
        }
    }

    /// `wdt:P31` of an author — human —, of a work — literary work —, of a publisher and of an
    /// editorial collection: the classes the website gives the entities it creates.
    private static let human: String = "wd:Q5"
    private static let literaryWork: String = "wd:Q47461344"
    private static let publisher: String = "wd:Q2085381"
    private static let editorialCollection: String = "wd:Q20655472"

    /// Creates a publisher, a collection or a person an edition names. A collection has no label:
    /// its name is a title, and it is created under its publisher, as the website requires.
    private func createEntity(
        label: String,
        language: String,
        kind: EntityCreationKind
    ) async throws -> String {
        switch kind {
        case .human:
            try await createEntity(
                label: label,
                language: language,
                claims: [WikidataProperty.instanceOf.rawValue: [Self.human]]
            )
        case .publisher:
            try await createEntity(
                label: label,
                language: language,
                claims: [WikidataProperty.instanceOf.rawValue: [Self.publisher]]
            )
        case .collection(let publisherUri):
            try await createEntity(
                labels: [:],
                claims: [
                    WikidataProperty.instanceOf.rawValue: [Self.editorialCollection],
                    WikidataProperty.title.rawValue: [label],
                    WikidataProperty.publisher.rawValue: [publisherUri]
                ]
            )
        }
    }

    /// Creates one entity on inventaire.io, and answers the uri it was created under.
    private func createEntity(
        label: String,
        language: String,
        claims: [String: [String]]
    ) async throws -> String {
        try await createEntity(labels: [language: label], claims: claims)
    }

    private func createEntity(
        labels: [String: String],
        claims: [String: [String]]
    ) async throws -> String {
        let response: CreatedEntityDTO? = try await apiService.send(
            toEndpoint: "/api/entities",
            method: "POST",
            payload: EntityCreationRequest(labels: labels, claims: claims),
            debug: true
        )

        guard let uri = response?.entity.uri else { throw NetworkError.badResponse }
        return uri
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
        let pages: ClaimLiteral? = after.properties.literal(of: .numberOfPages)
        if pages != before.properties.literal(of: .numberOfPages) {
            if case .integer(let count) = pages {
                edition.numberOfPages = count
            } else {
                edition.numberOfPages = nil
            }
        }
        try? modelContext.save()
    }
}
