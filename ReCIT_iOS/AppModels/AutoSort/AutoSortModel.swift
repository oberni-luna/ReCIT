//
//  AutoSortModel.swift
//  ReCIT_iOS
//
//  Owns the on-device session and runs the three phases end to end. The impure
//  half of auto-sort: the store, the model and the progress live here, and the
//  three pieces that can be got wrong — the histogram, the validator, the
//  assignment — live in `Model/AutoSort` as pure value types this only calls.
//
//  Nothing in this slice writes. `generatePlan` reads the inventory, consults the
//  model twice per run plus once per batch of genres, and publishes a plan for the
//  user to read. Creating the étagères is issue 0024; until then `cancel` is the
//  only other verb, and it throws the plan away.
//
//  The model never sees a book. Phase 1 is shown genres and counts, phase 2 is
//  shown genres and étagère names, phase 3 is arithmetic. That is what keeps a
//  three-thousand-book library the same cost as a three-hundred-book one — the
//  call count grows with distinct genres, never with books.
//
//  See PRD 0006.
//

import Foundation
import FoundationModels
import SwiftData

@MainActor
@Observable
final class AutoSortModel {

    /// Whether the feature can run, and why not when it cannot. Mirrored off
    /// `SystemLanguageModel.Availability` rather than exposed directly so views
    /// never import FoundationModels — and so issue 0025 has one place to hang the
    /// differentiated treatment each reason deserves.
    enum Availability: Equatable {
        case available
        /// The device cannot run Apple Intelligence at all. Nothing the user can do.
        case deviceNotEligible
        /// Apple Intelligence is switched off. Actionable — Settings fixes it.
        case appleIntelligenceNotEnabled
        /// The model is still downloading. Temporary.
        case modelNotReady

        var isAvailable: Bool { self == .available }
    }

    /// Where a run has got to. Named after what the user is waiting on rather than
    /// after the phase number, since it is what the screen says out loud.
    enum Phase: Equatable {
        case idle
        /// The genre backfill. Visibly the slowest step on a first run, and paid once.
        case analysingLibrary
        /// Phase 1.
        case designingShelves
        /// Phase 2.
        case sortingGenres
        /// Phase 3 has run and there is a plan to read.
        case ready
        case failed
    }

    /// Phase 1 is a judgement call, so it keeps a little room to make one — but only
    /// a little. At the default sampling the same library produced three taxonomies
    /// with nothing in common across three runs, one of them unusable, and a feature
    /// whose quality is a coin toss cannot be reviewed sensibly. Lowering the
    /// temperature trades novelty for the conventional answer, which for shelving a
    /// bookshelf is the right trade.
    static let taxonomyOptions: GenerationOptions = .init(temperature: 0.3)

    /// Phase 2 is not a judgement call at all — the étagères are already chosen and
    /// each genre has a best fit among them — so it is pushed as close to
    /// deterministic as the API allows. Creativity here shows up as a hallucinated
    /// shelf name, which is pure cost.
    static let mappingOptions: GenerationOptions = .init(temperature: 0.1)

    /// One genre batch per call in phase 2. Small enough that a batch and the
    /// étagère list it repeats sit comfortably inside the context window, and the
    /// batch count is bounded by distinct genres — the whole cost argument.
    private static let mappingBatchSize: Int = 10

    private let genreEnrichment: GenreEnrichmentModel

    /// Shared channel used to surface a failure to the UI.
    var errorReporter: AppErrorReporter?

    private(set) var phase: Phase = .idle

    /// The proposal, or `nil` when there is nothing to read. Never written anywhere.
    private(set) var plan: AutoSortPlan?

    /// The collection the taxonomy was designed from. Kept past the run because it
    /// is what a taxonomy has to be judged against — a proposal is only sensible
    /// relative to the distribution that produced it — and because phase 2 batches
    /// its genres out of it.
    private(set) var histogram: GenreHistogram = .init(books: [])

    /// What the validator threw away on this run. Surfaced rather than swallowed:
    /// a taxonomy that only half survived is worth knowing about even when the plan
    /// looks fine.
    private(set) var rejections: [ShelfMappingValidator.Rejection] = []

    /// The étagère names phase 1 proposed, before assignment dropped the empty ones.
    private(set) var proposedTaxonomy: [String] = []

    /// A session per run rather than one for the app's lifetime: each run is a fresh
    /// question about a collection that may have changed, and a stale transcript
    /// would spend context on the previous library.
    @ObservationIgnored private var session: LanguageModelSession?

    init(genreEnrichment: GenreEnrichmentModel, errorReporter: AppErrorReporter? = nil) {
        self.genreEnrichment = genreEnrichment
        self.errorReporter = errorReporter
    }

    // MARK: - Availability

    var availability: Availability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            return .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            return .modelNotReady
        @unknown default:
            return .modelNotReady
        }
    }

    var isRunning: Bool {
        switch phase {
        case .analysingLibrary, .designingShelves, .sortingGenres: true
        case .idle, .ready, .failed: false
        }
    }

    /// The wait's own copy, kept next to the step that causes it. The genre backfill
    /// borrows the enrichment model's wording so the first run reads as one
    /// continuous analysis rather than two unrelated stalls.
    var statusText: String {
        switch phase {
        case .idle: ""
        case .analysingLibrary: genreEnrichment.statusText
        case .designingShelves: "Conception des étagères…"
        case .sortingGenres: "Rangement des genres…"
        case .ready: ""
        case .failed: ""
        }
    }

    // MARK: - Generating a plan

    /// Reads the user's unshelved books and proposes a set of étagères for them.
    /// Writes nothing — not the plan, not the étagères, not a single field.
    ///
    /// Never throws: a failure leaves `phase` at `.failed`, keeps whatever the genre
    /// backfill already persisted, and surfaces the error through the shared
    /// `AppErrorReporter`.
    func generatePlan(forUser user: User, modelContext: ModelContext) async {
        plan = nil
        rejections = []
        proposedTaxonomy = []

        // The backfill first: the whole design rests on genre data, and this is its
        // only caller. Idempotent, so a second run costs nothing.
        phase = .analysingLibrary
        await genreEnrichment.enrichUnshelvedWorks(forUser: user, modelContext: modelContext)

        let books: [AutoSortBook] = unshelvedBooks(forUser: user, modelContext: modelContext)
        histogram = .init(books: books)

        // No genre anywhere is a real outcome, not a failure: these books stay
        // unshelved rather than being guessed at from title and author.
        guard !histogram.isEmpty else {
            plan = .init(nothingToPropose: books)
            phase = .ready
            return
        }

        do {
            let session: LanguageModelSession = .init(instructions: AutoSortPrompts.instructions)
            self.session = session

            phase = .designingShelves
            let taxonomy: [String] = try await proposeTaxonomy(session: session)
            proposedTaxonomy = taxonomy

            phase = .sortingGenres
            let assignments: [ShelfMappingValidator.RawAssignment] = try await mapGenres(
                session: session,
                taxonomy: taxonomy
            )

            let mapping: ValidatedGenreMapping = try ShelfMappingValidator.validate(
                taxonomy: taxonomy,
                assignments: assignments,
                offeredGenres: histogram.genres
            )
            rejections = mapping.rejections

            plan = .init(mapping: mapping, books: books)
            phase = .ready
            logOutcome(mapping: mapping)
        } catch {
            phase = .failed
            errorReporter?.report(error)
        }
    }

    /// Throws the proposal away. There is nothing to undo — no étagère was created,
    /// no book was moved, no field was written — so this is the whole of "cancel".
    func cancel() {
        plan = nil
        rejections = []
        proposedTaxonomy = []
        histogram = .init(books: [])
        session = nil
        phase = .idle
    }

    // MARK: - Phase 1

    private func proposeTaxonomy(session: LanguageModelSession) async throws -> [String] {
        let response = try await session.respond(
            to: AutoSortPrompts.taxonomyPrompt(histogram: histogram),
            generating: AutoSortTaxonomyDraft.self,
            options: Self.taxonomyOptions
        )
        return response.content.etageres
    }

    // MARK: - Phase 2

    /// One call per batch of genres, each carrying the full étagère list. Batched
    /// rather than one call per genre because a genre in isolation gives the model
    /// nothing to weigh it against, and rather than one call for everything because
    /// a long genre list plus a long answer overruns the context.
    private func mapGenres(
        session: LanguageModelSession,
        taxonomy: [String]
    ) async throws -> [ShelfMappingValidator.RawAssignment] {
        var assignments: [ShelfMappingValidator.RawAssignment] = []

        for batch in histogram.genres.splitInSubArrays(of: Self.mappingBatchSize) {
            let response = try await session.respond(
                to: AutoSortPrompts.mappingPrompt(genres: batch, shelfNames: taxonomy),
                generating: AutoSortMappingDraft.self,
                options: Self.mappingOptions
            )
            assignments.append(contentsOf: response.content.affectations.map {
                .init(genre: $0.genre, shelfName: $0.etagere)
            })
        }
        return assignments
    }

    // MARK: - Reading the inventory

    /// The user's books that are on no étagère, newest first. Only these are ever
    /// considered, which is what makes the feature purely additive: nothing the user
    /// arranged by hand can be disturbed, and a re-run picks up what is left rather
    /// than duplicating work.
    ///
    /// A copy's genres are the union of the genres of the works behind its edition,
    /// in claim order and deduplicated; `AutoSortBook.primaryGenre` then decides
    /// which single one it is filed under.
    private func unshelvedBooks(forUser user: User, modelContext: ModelContext) -> [AutoSortBook] {
        let ownerId: String = user._id
        let descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { item in item.ownerId == ownerId },
            sortBy: [SortDescriptor(\.created, order: .reverse)]
        )
        let items: [InventoryItem] = (try? modelContext.fetch(descriptor)) ?? []

        return items.filter(\.shelves.isEmpty).map { item in
            var seen: Set<String> = []
            let genres: [String] = (item.edition?.works ?? [])
                .flatMap(\.genres)
                .filter { seen.insert($0).inserted }

            return .init(
                id: item._id,
                title: item.edition?.title ?? "",
                authors: item.edition?.authorNames.joined(separator: ", ") ?? "",
                coverImageUrl: item.edition?.image,
                genres: genres
            )
        }
    }

    // MARK: - Logging

    /// The taxonomy and what the validator refused are the two things a human tuning
    /// the prompts needs to see, so they go to the console alongside the other sync
    /// traces rather than being inferred from the screen.
    private func logOutcome(mapping: ValidatedGenreMapping) {
        print("## Auto-sort taxonomy: \(mapping.shelfNames.joined(separator: " | "))")
        print("## Auto-sort mapped \(mapping.shelfByGenreKey.count)/\(histogram.entries.count) genre(s), \(mapping.rejections.count) rejected, \(mapping.unmappedGenres.count) unmapped")
        for rejection in mapping.rejections {
            print("##   rejected: \(rejection)")
        }
    }
}
