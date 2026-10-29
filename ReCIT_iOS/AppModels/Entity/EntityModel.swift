//
//  EntityModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import SwiftData
import Foundation

@MainActor
@Observable
final class EntityModel {
    private let apiService: APIServicing

    init(apiService: APIServicing) {
        self.apiService = apiService
    }

    // MARK: - Cache-first access (no network)

    /// Returns the cached author for `uri` if present, without hitting the network.
    func localAuthor(modelContext: ModelContext, uri: String) -> Author? {
        try? getLocalAuthor(modelContext: modelContext, uri: uri)
    }

    /// Returns the cached work for `uri` if present, without hitting the network.
    func localWork(modelContext: ModelContext, uri: String) -> Work? {
        try? getLocalWork(modelContext: modelContext, uri: uri)
    }

    /// Returns the cached edition for `uri` if present, without hitting the network.
    func localEdition(modelContext: ModelContext, uri: String) -> Edition? {
        try? getLocalEdition(modelContext: modelContext, uri: uri)
    }

    // MARK: - Background revalidation (upsert)

    /// Fetches the author remotely and merges the fresh values into the cached
    /// entity in place (inserting it if absent). Existing data is preserved when
    /// the server responds with a sparse payload. If the remote call yields no
    /// entity, the current cached value (if any) is returned unchanged.
    func refreshAuthor(modelContext: ModelContext, uri: String) async throws -> Author? {
        guard let authorDto = try await fetchEntities(modelContext: modelContext, uris: [uri])?.first else {
            return try? getLocalAuthor(modelContext: modelContext, uri: uri)
        }

        let author: Author? = try modelContext.upsertAuthors([authorDto], apiService: apiService).first
        try modelContext.save()
        return author
    }

    /// Fetches the work remotely and merges the fresh values into the cached
    /// entity in place (inserting it if absent), also resolving its authors.
    /// If the remote call yields no entity, the current cached value is returned.
    func refreshWork(modelContext: ModelContext, uri: String) async throws -> Work? {
        guard let workDto = try await fetchEntities(modelContext: modelContext, uris: [uri])?.first else {
            return try? getLocalWork(modelContext: modelContext, uri: uri)
        }

        let authorUris: [String] = workDto.claims[WikidataProperty.author.rawValue]?
            .compactMap { $0.getStringValue() } ?? []
        let authors: [Author] = (try? await getOrFetchAuthors(modelContext: modelContext, uris: authorUris)) ?? []

        let work: Work = try modelContext.upsertWork(workDto, authors: authors, apiService: apiService)
        try modelContext.save()
        return work
    }

    /// Fetches the edition remotely and merges the fresh values into the cached
    /// entity in place (inserting it if absent), also resolving its works.
    /// If the remote call yields no entity, the current cached value is returned.
    ///
    /// `autocreate` is for the scanner, and only for it: asked with an `isbn:` uri, the server
    /// will create the edition from its own book-facts service rather than answer that it has
    /// none. See `fetchEntities`.
    func refreshEdition(
        modelContext: ModelContext,
        uri: String,
        autocreate: Bool = false
    ) async throws -> Edition? {
        guard let editionDto = try await fetchEntities(
            modelContext: modelContext,
            uris: [uri],
            autocreate: autocreate
        )?.first else {
            return try? getLocalEdition(modelContext: modelContext, uri: uri)
        }

        let works: [Work] = try await resolveEditionWorks(from: editionDto, modelContext: modelContext)

        let edition: Edition = try modelContext.upsertEdition(editionDto, works: works, apiService: apiService)
        try modelContext.save()
        return edition
    }

    // MARK: - Best edition of a work (ADR 0002, Move 3)

    /// The edition to open for `workUri`, resolved over the network and upserted in place — or
    /// `nil` when the work has no edition at all, which is a thing that exists and which the
    /// caller renders rather than swallows.
    ///
    /// This is the search's route to a book: `/api/search` cannot return editions, so a tapped
    /// result names a work and the app picks the edition. It ranks over DTOs through
    /// `WorkEditionResolver` and **persists only the winner** — inserting every edition the work
    /// has would be 127 of them for *1984*, on one tap.
    ///
    /// `heldEditionUris` is read here rather than inside the resolver: the ranking must not know
    /// what a `ModelContext` is.
    func resolveBestEdition(modelContext: ModelContext, workUri: String) async throws -> Edition? {
        // A second tap opens from the store and pays nothing. The edition is then revalidated
        // in the background and the ranking replayed: the screen already on display never
        // changes *book* under the reader's eyes, but the book it shows is brought up to date in
        // place (ADR 0001, invariant 2), and a ranking that has moved is recorded for the next
        // visit.
        if let work = localWork(modelContext: modelContext, uri: workUri),
           let preferred = work.preferredEditionUri,
           let edition = localEdition(modelContext: modelContext, uri: preferred) {
            revalidatePreferredEdition(modelContext: modelContext, workUri: workUri)
            return edition
        }

        guard let uri = try await rankBestEditionUri(modelContext: modelContext, workUri: workUri) else {
            return nil
        }

        let edition: Edition? = try await refreshEdition(modelContext: modelContext, uri: uri)
        rememberPreferredEdition(uri, forWorkUri: workUri, modelContext: modelContext)
        return edition
    }

    /// Runs the ladder and answers the winning uri, or `nil` when the work has no edition.
    private func rankBestEditionUri(modelContext: ModelContext, workUri: String) async throws -> String? {
        let resolver: WorkEditionResolver = .init(apiService: apiService)

        return try await resolver.bestEditionUri(
            forWorkUri: workUri,
            originalLang: localWork(modelContext: modelContext, uri: workUri)?.originalLang,
            heldEditionUris: heldEditionUris(modelContext: modelContext)
        )
    }

    /// Writes the preference onto the work, **looking it up again** rather than writing through
    /// a reference held across the two round trips this follows — that is the shape of the crash
    /// in issue 0067.
    ///
    /// The lookup is also why this is called after `refreshEdition` and not before: the search
    /// persists nothing, so until the edition's `wdt:P629` has been resolved there is no `Work`
    /// row to write to. Fetching the work earlier would be a third request for nothing.
    private func rememberPreferredEdition(
        _ editionUri: String,
        forWorkUri workUri: String,
        modelContext: ModelContext
    ) {
        guard let work = localWork(modelContext: modelContext, uri: workUri),
              work.preferredEditionUri != editionUri else {
            return
        }

        work.preferredEditionUri = editionUri
        try? modelContext.save()
    }

    /// The background half of a cached open: it refreshes the edition that was just handed to
    /// the screen, and then replays the ladder in case the corpus moved.
    ///
    /// **Refreshing the shown edition is not optional, and leaving it out was a bug.** The first
    /// draft only called `refreshEdition` when the ranking landed on a *different* uri — which is
    /// almost never — so an edition opened from the preference was returned from the store and
    /// never revalidated again. Whatever that row happened to hold was permanent: the Harry
    /// Potter edition `wd:Q58464836`, cached as `Unknown` by the title mapping that preceded
    /// `EditionTitle`, kept that name on every visit however many times it was opened. That is
    /// precisely the cache-first-then-upsert-in-place ADR 0001 asks for, skipped while claiming
    /// to follow it (invariant 2).
    ///
    /// Failures are swallowed: the user is looking at a book either way, and a stale field is
    /// better than a stuck screen.
    ///
    /// One pass per work at a time — a reader who taps, goes back and taps again should not
    /// stack three identical re-rankings.
    private func revalidatePreferredEdition(modelContext: ModelContext, workUri: String) {
        guard revalidatingWorkUris.contains(workUri) == false else { return }
        revalidatingWorkUris.insert(workUri)

        Task { [weak self] in
            defer { self?.revalidatingWorkUris.remove(workUri) }
            await self?.performRevalidation(modelContext: modelContext, workUri: workUri)
        }
    }

    /// The revalidation itself, awaitable.
    ///
    /// Split out from the fire-and-forget wrapper above so a test can drive it: a detached
    /// `Task` is exactly the shape a regression hides in, and this code path has already grown
    /// one bug that only a user could see.
    func performRevalidation(modelContext: ModelContext, workUri: String) async {
        // The edition the screen is showing, revalidated whatever the ladder then says. It was
        // opened without a round trip; this is that round trip.
        if let shown = localWork(modelContext: modelContext, uri: workUri)?.preferredEditionUri {
            _ = try? await refreshEdition(modelContext: modelContext, uri: shown)
        }

        guard let uri = try? await rankBestEditionUri(modelContext: modelContext, workUri: workUri),
              uri != localWork(modelContext: modelContext, uri: workUri)?.preferredEditionUri
        else {
            return
        }

        _ = try? await refreshEdition(modelContext: modelContext, uri: uri)
        rememberPreferredEdition(uri, forWorkUri: workUri, modelContext: modelContext)
    }

    /// The works whose preference is being re-ranked right now.
    private var revalidatingWorkUris: Set<String> = []

    /// The editions this device already holds a copy of — mine and my friends'. A free signal:
    /// the items are already in the store, synced, and nothing here goes to the network.
    ///
    /// `isStillInTheStore` guards the relationship read, because a copy deleted a moment ago can
    /// still be reachable from a fetch and reading a persisted property off it traps rather than
    /// returning nil (issue 0065).
    private func heldEditionUris(modelContext: ModelContext) -> Set<String> {
        let items: [InventoryItem] = (try? modelContext.fetch(FetchDescriptor<InventoryItem>())) ?? []

        return .init(items.compactMap { item in
            guard item.isStillInTheStore else { return nil }
            return item.edition?.uri
        })
    }

    // MARK: - Authors

    func getOrFetchAuthors(modelContext: ModelContext, uris: [String]) async throws -> [Author]? {
        var authors: [Author] = []
        var urisToFetch: [String] = []
        for uri in uris {
            // A nameless author is fetched again: it was stored before `EntityLabel` read the
            // `mul` label, and the cache alone would keep it nameless for good.
            if let author = try? getLocalAuthor(modelContext: modelContext, uri: uri), author.name.isEmpty == false {
                authors.append(author)
            } else {
                urisToFetch.append(uri)
            }
        }

        guard let authorsDto = try await fetchEntities(modelContext: modelContext, uris: urisToFetch, debug: true) else {
            return authors
        }

        // Upserted: the server may answer a uri with the entity it now redirects to, which the
        // store can hold already.
        authors.append(contentsOf: try modelContext.upsertAuthors(authorsDto, apiService: apiService))
        try modelContext.save()

        return authors
    }

    func getAuthorWorks(modelContext: ModelContext, author: Author) async throws -> [Work]? {
        let endpoint: String = "/api/entities/author-works?uri=\(author.uri)&refresh=false"
        let response: AuthorWorksDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        guard let authorWorkDTO = response?.works else { return nil }
        guard let works: [Work] = try? await getOrFetchWorks(modelContext: modelContext, uris: authorWorkDTO.map(\.uri)) else {
            return nil
        }

        for work in works {
            work.mergeAuthors([author])
        }

        try modelContext.save()
        return works
    }

    // MARK: - Works

    func getOrFetchWorks(modelContext: ModelContext, uris: [String]) async throws -> [Work]? {
        var works: [Work] = []
        var urisToFetch: [String] = []
        for uri in uris {
            if let work = try? getLocalWork(modelContext: modelContext, uri: uri) {
                works.append(work)
            } else {
                urisToFetch.append(uri)
            }
        }

        guard let worksDto = try await fetchEntities(modelContext: modelContext, uris: urisToFetch) else {
            return nil
        }

        for workDto in worksDto {
            let authorUris: [String] = workDto.claims[WikidataProperty.author.rawValue]?
                .compactMap { $0.getStringValue() } ?? []
            let authors: [Author] = (try? await getOrFetchAuthors(modelContext: modelContext, uris: authorUris)) ?? []

            works.append(try modelContext.upsertWork(workDto, authors: authors, apiService: apiService))
        }
        return works
    }

    /// The uris of `work`'s editions, in one `reverse-claims` call, nothing fetched or stored:
    /// what the book screen needs to know whether to offer « Autres éditions ». Inserting them
    /// all, as it once did, froze it for minutes on « L'Appel de la forêt »'s 7742 editions.
    func workEditionUris(work: Work) async throws -> [String] {
        let endpoint: String = "/api/entities/reverse-claims?property=wdt:P629&value=\(work.uri)&refresh=false"
        let response: WorkEditionsDTO? = try await apiService.fetchData(fromEndpoint: endpoint)
        return response?.uris ?? []
    }

    /// The editions of `work`, upserted in place — the screen « Éditions »'s revalidation
    /// (PRD 0028).
    ///
    /// The editions not held yet, or held but not listed under this work, are fetched first,
    /// fifty to a call, and saved call by call, so the list fills as they come. The ones already
    /// listed are fetched again too once a day (`Work.editionsNeedRefresh`), and those in
    /// `refreshing` always: an edition taken from the cache as it is, cached before editions
    /// carried an ISBN, would never gain one, and the duplicate detection would never see it. A work can have thousands of editions — « L'Appel de la
    /// forêt » has 7742 —, which is why that second pass is not made at every visit. The
    /// publishers' and collections' names are read once, for those not known yet.
    ///
    /// An edition this work used to list and the server no longer names — merged into another,
    /// most often — is detached from the work rather than deleted: other works, items and lists
    /// may still point at it. A failed call keeps the calls before it and detaches nothing.
    func refreshWorkEditions(
        modelContext: ModelContext,
        work: Work,
        refreshing: Set<String> = [],
        now: Date = .now
    ) async throws {
        let endpoint: String = "/api/entities/reverse-claims?property=wdt:P629&value=\(work.uri)&refresh=false"
        guard let uris = (try await apiService.fetchData(fromEndpoint: endpoint) as WorkEditionsDTO?)?.uris else { return }

        let refreshesAll: Bool = work.editionsNeedRefresh(at: now)
        let listedHere: Set<String> = .init(work.editions.map(\.uri))
        let missing: [String] = uris.filter { listedHere.contains($0) == false || refreshing.contains($0) }
        let missingSet: Set<String> = .init(missing)
        let held: [String] = refreshesAll ? uris.filter { missingSet.contains($0) == false } : []

        var listed: Set<String> = .init(uris)
        var works: [String: Work] = [work.uri: work]
        for batch in (missing + held).splitInSubArrays(of: 50) {
            guard let editionDtos = try await fetchEntities(modelContext: modelContext, uris: batch) else { continue }
            let stored: [String: Edition] = try modelContext.editions(uris: editionDtos.map(\.uri))
            for editionDto in editionDtos {
                let editionWorks: [Work] = await resolveEditionWorks(from: editionDto, among: &works, modelContext: modelContext)
                let edition: Edition = try modelContext.upsertEdition(
                    editionDto,
                    works: editionWorks,
                    apiService: apiService,
                    held: stored
                )
                edition.mergeWorks([work])
                listed.insert(edition.uri)
            }
            try modelContext.save()
        }

        for edition in work.editions where listed.contains(edition.uri) == false {
            edition.works.removeAll { $0.uri == work.uri }
        }

        await nameRelatives(of: work.editions)
        if refreshesAll {
            work.editionsRefreshedAt = now
        }
        try modelContext.save()
    }

    /// Fills the publisher and collection names `editions` lack, in one `by-uris` call. A
    /// collection has no label, only a title — `EditableEditionDTO.displayName` reads both. A
    /// failure leaves the names unknown; the row shows what it has.
    private func nameRelatives(of editions: [Edition]) async {
        let missing: [String] = Array(Set(
            editions.compactMap { $0.publisherName == nil ? $0.publisherUri : nil }
            + editions.compactMap { $0.collectionName == nil ? $0.collectionUri : nil }
        )).sorted()
        guard missing.isEmpty == false else { return }

        var names: [String: String] = [:]
        for batch in missing.splitInSubArrays(of: 50) {
            let endpoint: String = "/api/entities/by-uris?uris=\(batch.joined(separator: "|"))&attributes=info|labels|claims&lang=fr"
            guard let response: EditableEditionsDTO = try? await apiService.fetchData(fromEndpoint: endpoint) else { continue }
            for (key, entity) in response.entities {
                guard let name = entity.displayName else { continue }
                names[key] = name
                names[entity.uri] = name
            }
            for (asked, canonical) in response.redirects ?? [:] {
                names[asked] = names[canonical]
            }
        }

        for edition in editions {
            if edition.publisherName == nil, let uri = edition.publisherUri {
                edition.publisherName = names[uri]
            }
            if edition.collectionName == nil, let uri = edition.collectionUri {
                edition.collectionName = names[uri]
            }
        }
    }

    // MARK: - Editions

    func getLocalEdition(modelContext: ModelContext, uri: String) throws -> Edition? {
        let predicate: Predicate<Edition> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<Edition> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Extracts

    func getOrFetchExtract(forUri uri: String, modelContext: ModelContext) async throws -> WpExtract? {
        if let extract = try getLocalExtract(modelContext: modelContext, uri: uri), !extract.content.isEmpty {
            return extract
        }

        if let extractDto: ExtractDTO = try await fetchExtract(for: uri) {
            let extract: WpExtract = .init(uri: uri, content: extractDto.extract, url: extractDto.url)
            modelContext.insert(extract)
            try modelContext.save()
            return extract
        }

        return nil
    }

    func getLocalExtract(modelContext: ModelContext, uri: String) throws -> WpExtract? {
        let predicate: Predicate<WpExtract> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<WpExtract> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func fetchExtract(for uri: String) async throws -> ExtractDTO? {
        guard let summariesDTO: SummariesDTO = try? await apiService.fetchData(
            fromEndpoint: "/api/data/summaries?uri=\(uri)&langs=fr&refresh=false"
        ) else {
            return nil
        }

        if let summary: SummaryDTO = summariesDTO.summaries.first(where: {
            $0.key == WikidataProperty.summary.rawValue && $0.lang == "fr"
        }) {
            return .init(extract: summary.text ?? "", url: summary.link)
        } else if let summary: SummaryDTO = summariesDTO.summaries.first(where: { $0.key == "frwiki" }) {
            guard let sitelink: SitelinkDTO = summary.sitelink else { return nil }
            return try? await apiService.fetchData(
                fromEndpoint: "/api/data/wp-extract?lang=fr&title=\(sitelink.title)"
            )
        }

        return nil
    }

    // MARK: - Private helpers

    /// Extracts work URIs from an edition DTO's claims and fetches the associated works and their authors.
    /// `resolveEditionWorks`, through `works`: the editions of one work nearly all name that
    /// work, and it is looked up once rather than once per edition.
    private func resolveEditionWorks(
        from editionDto: EntityResultDTO,
        among works: inout [String: Work],
        modelContext: ModelContext
    ) async -> [Work] {
        let workUris: [String] = editionDto.claims[WikidataProperty.editionOf.rawValue]?
            .compactMap { $0.getStringValue() } ?? []
        let unknown: [String] = workUris.filter { works[$0] == nil }
        if unknown.isEmpty == false {
            for fetched in (try? await getOrFetchWorks(modelContext: modelContext, uris: unknown)) ?? [] {
                works[fetched.uri] = fetched
            }
        }
        return workUris.compactMap { works[$0] }
    }

    private func resolveEditionWorks(
        from editionDto: EntityResultDTO,
        modelContext: ModelContext
    ) async throws -> [Work] {
        let workUris: [String] = editionDto.claims[WikidataProperty.editionOf.rawValue]?
            .compactMap { $0.getStringValue() } ?? []

        guard !workUris.isEmpty else { return [] }

        return (try? await getOrFetchWorks(modelContext: modelContext, uris: workUris)) ?? []
    }

    /// Fetches entities by uri.
    ///
    /// `autocreate` asks inventaire.io to **make the entity rather than answer that it has
    /// none**, which it can do for an `isbn:` uri: the server goes to its own book-facts
    /// service and, when that service knows the ISBN, writes a complete edition — title,
    /// publication date, publisher, language, the work it belongs to, and a cover — then
    /// returns it like any other. That is why the website's scanner almost never has to ask
    /// anybody to fill in a form. Off by default: it is a *write*, and only the scanner's
    /// lookup has a reason to ask for one. See PRD 0015 and feature 0020.
    func fetchEntities(
        modelContext: ModelContext,
        uris: [String],
        autocreate: Bool = false,
        debug: Bool = false
    ) async throws -> [EntityResultDTO]? {
        var results: [EntityResultDTO] = []

        for uriBatch in uris.splitInSubArrays(of: 50) {
            var entityUrl: String = "/api/entities/by-uris?uris=\(uriBatch.joined(separator: "|"))&attributes=info|labels|descriptions|claims|image&lang=fr"
            if autocreate {
                entityUrl += "&autocreate=true"
            }
            let resultsDto: EntityResultsDTO? = try await apiService.fetchData(fromEndpoint: entityUrl, debug: debug)
            results.append(contentsOf: resultsDto.map { Array($0.entities.values) } ?? [])
        }

        return results
    }

    func getLocalWork(modelContext: ModelContext, uri: String) throws -> Work? {
        let predicate: Predicate<Work> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<Work> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    private func getLocalAuthor(modelContext: ModelContext, uri: String) throws -> Author? {
        let predicate: Predicate<Author> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<Author> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
}
