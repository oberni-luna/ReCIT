//
//  GenreEnrichmentModel.swift
//  ReCIT_iOS
//
//  Backfills `Work.genres` for the works behind the user's unshelved books.
//
//  On demand rather than folded into the regular entity sync: that path already
//  contends with optimistic shelf-membership writes (see PRD 0004), and a
//  backfill is needed regardless for works synced before genres existed.
//
//  Two batched passes, both through `by-uris`: works → genre uris (`wdt:P136`),
//  then genre uris → French labels. A few hundred works is a handful of calls,
//  not one per book. Results are persisted per batch, so a failure halfway keeps
//  everything already fetched and only the remainder is retried next run.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class GenreEnrichmentModel {

    /// What the user is being told is happening. The first run is visibly slower
    /// than later ones because it does the backfill, so the wait is presented as
    /// analysing the library rather than left to look like a slow model.
    enum Phase: Equatable {
        case idle
        case analysing
        case finished
        case failed
    }

    /// Matches the batch size `EntityModel.fetchEntities` uses internally, so one
    /// chunk here is exactly one request — which is what makes progress advance
    /// smoothly instead of jumping at the end.
    private static let batchSize: Int = 50

    private let apiService: APIServicing
    private let entityModel: EntityModel

    /// Shared channel used to surface a background failure to the UI.
    var errorReporter: AppErrorReporter?

    private(set) var phase: Phase = .idle

    /// Works this run has to fetch, and how many of them it has got through.
    private(set) var worksToEnrich: Int = 0
    private(set) var worksProcessed: Int = 0

    /// Tally over the whole scope, not just this run's fetches, so it stays
    /// meaningful on a second run that has nothing left to fetch.
    private(set) var coverage: GenreCoverage = .empty

    /// Genre uri → French label, memoised for the run. Libraries repeat genres
    /// heavily, so this collapses most of the second pass.
    @ObservationIgnored private var genreLabels: [String: String] = [:]

    init(
        apiService: APIServicing,
        entityModel: EntityModel,
        errorReporter: AppErrorReporter? = nil
    ) {
        self.apiService = apiService
        self.entityModel = entityModel
        self.errorReporter = errorReporter
    }

    // MARK: - Progress

    /// 0…1, and 1 when there is nothing to do, so a progress view does not sit
    /// at zero while the step completes instantly on a second run.
    var progress: Double {
        guard worksToEnrich > 0 else { return 1 }
        return min(1, Double(worksProcessed) / Double(worksToEnrich))
    }

    var isAnalysing: Bool {
        phase == .analysing
    }

    /// The wait's own copy, kept next to the step that causes it.
    var statusText: String {
        String(localized: "genre.enrichment.analysing")
    }

    // MARK: - Enrichment

    /// Fetches and persists genres for every work behind one of `user`'s unshelved
    /// books that has not been enriched yet. Works already known — including those
    /// known to have no genre — are skipped, so a second run costs nothing.
    ///
    /// Never throws: a mid-run network failure keeps what was already persisted,
    /// leaves the rest pending for the next run, and surfaces the error through
    /// the shared `AppErrorReporter`.
    func enrichUnshelvedWorks(forUser user: User, modelContext: ModelContext) async {
        phase = .analysing
        worksProcessed = 0

        let works: [Work] = unshelvedWorks(forUser: user, modelContext: modelContext)
        let pending: [Work] = works.filter { $0.genresEnrichedAt == nil }
        worksToEnrich = pending.count

        guard !pending.isEmpty else {
            coverage = .init(works: works)
            phase = .finished
            return
        }

        do {
            for batch in pending.splitInSubArrays(of: Self.batchSize) {
                try await enrich(batch: batch, modelContext: modelContext)
                worksProcessed += batch.count
            }
            coverage = .init(works: works)
            phase = .finished
        } catch {
            coverage = .init(works: works)
            phase = .failed
            errorReporter?.report(error)
        }
        logCoverage()
    }

    /// Coverage of the current scope without fetching anything, so a caller can
    /// judge the data before deciding to run — or after, from a fresh screen.
    func currentCoverage(forUser user: User, modelContext: ModelContext) -> GenreCoverage {
        .init(works: unshelvedWorks(forUser: user, modelContext: modelContext))
    }

    // MARK: - Private helpers

    /// The enriched-versus-empty split is the first honest signal on whether an
    /// AI shelf taxonomy is worth building on this data, so it is logged on every
    /// run alongside the other sync traces.
    private func logCoverage() {
        print("## Genre enrichment \(phase): \(coverage.worksWithGenres) work(s) with genres, \(coverage.worksWithoutGenres) without, \(coverage.worksPending) pending, out of \(coverage.worksConsidered)")
    }

    /// One batch: fetch the works' entities, resolve every genre uri they name,
    /// then write the labels back. Saved before returning so a later batch
    /// failing never costs this one.
    private func enrich(batch: [Work], modelContext: ModelContext) async throws {
        var worksByUri: [String: Work] = .init(minimumCapacity: batch.count)
        for work in batch {
            worksByUri[work.uri] = work
        }

        let entities: [EntityResultDTO] = (try await entityModel.fetchEntities(
            modelContext: modelContext,
            uris: batch.map(\.uri)
        )) ?? []

        var genreUrisByWork: [String: [String]] = .init(minimumCapacity: entities.count)
        var urisToResolve: Set<String> = []

        for entity in entities {
            let genreUris: [String] = entity.claims[WikidataProperty.genre.rawValue]?
                .compactMap { $0.getStringValue() } ?? []
            genreUrisByWork[entity.uri] = genreUris
            for uri in genreUris where genreLabels[uri] == nil {
                urisToResolve.insert(uri)
            }
        }

        try await resolveGenreLabels(uris: Array(urisToResolve))

        for (workUri, genreUris) in genreUrisByWork {
            guard let work = worksByUri[workUri] else { continue }
            work.applyEnrichedGenres(labels(for: genreUris))
        }

        try modelContext.save()
    }

    /// Genre claims come back as bare Wikidata uris (`wd:Q1080374`), which say
    /// nothing to a model asked to name shelves — so each is resolved to its
    /// French label in batched `attributes=labels` calls.
    private func resolveGenreLabels(uris: [String]) async throws {
        for batch in uris.splitInSubArrays(of: Self.batchSize) {
            let endpoint: String = "/api/entities/by-uris?uris=\(batch.joined(separator: "|"))&attributes=labels&lang=fr"
            let response: EntityLabelsResultsDTO? = try await apiService.fetchData(fromEndpoint: endpoint)
            for (uri, entity) in response?.entities ?? [:] {
                guard let label = entity.labels["fr"] ?? entity.labels["en"] ?? entity.labels.values.first,
                      !label.isEmpty else { continue }
                genreLabels[uri] = label
            }
        }
    }

    /// Unresolved uris are dropped rather than kept verbatim: `wd:Q1080374` in a
    /// prompt is noise, and a genre nobody can name is not a genre.
    private func labels(for genreUris: [String]) -> [String] {
        var seen: Set<String> = []
        return genreUris.compactMap { genreLabels[$0] }.filter { seen.insert($0).inserted }
    }

    /// The works behind `user`'s books that are on no étagère, deduplicated. Books
    /// already filed by hand are out of scope, exactly as the auto-sort run is.
    private func unshelvedWorks(forUser user: User, modelContext: ModelContext) -> [Work] {
        let ownerId: String = user._id
        let descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { item in item.ownerId == ownerId }
        )
        let items: [InventoryItem] = (try? modelContext.fetch(descriptor)) ?? []

        var seen: Set<String> = []
        var works: [Work] = []
        for item in items where item.shelves.isEmpty {
            for work in (item.edition?.works ?? []) where seen.insert(work.uri).inserted {
                works.append(work)
            }
        }
        return works
    }
}
