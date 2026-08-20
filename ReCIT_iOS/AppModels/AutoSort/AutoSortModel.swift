//
//  AutoSortModel.swift
//  ReCIT_iOS
//
//  Owns the on-device session and runs the three phases end to end. The impure
//  half of auto-sort: the store, the model and the progress live here, and the
//  three pieces that can be got wrong — the histogram, the validator, the
//  assignment — live in `Model/AutoSort` as pure value types this only calls.
//
//  `generatePlan` reads the inventory, consults the model twice per run plus once
//  per batch of genres, and publishes a plan for the user to read; it writes
//  nothing. `apply` then turns an approved plan into real étagères, and `cancel`
//  throws the proposal away — which costs nothing, since a proposal is all it was.
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
    /// `SystemLanguageModel.Availability` rather than exposed directly so views never
    /// import FoundationModels. What each reason is worth telling the user is not
    /// decided here: `AutoSortEntryPoint` maps these four states onto the shape an
    /// entry point should take.
    enum Availability: Equatable {
        case available
        /// The device cannot run Apple Intelligence at all. Nothing the user can do.
        case deviceNotEligible
        /// Apple Intelligence is switched off. Actionable — Settings fixes it.
        case appleIntelligenceNotEnabled
        /// The model is still downloading. Temporary.
        case modelNotReady
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
        /// The approved plan is being written, one étagère at a time.
        case applying
        /// The run has stopped writing. Not the same as "everything landed": a partial
        /// failure ends here too, and `applyProgress` is what says which it was. Kept
        /// as one case rather than two so the screen has a single "the writing is over,
        /// read the marks" state and cannot show a success it has not checked.
        case applied
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

    /// The one path to `/api/shelves`. Injected rather than reimplemented so the apply
    /// goes through the same create and `add-items` writes the rest of the app uses.
    private let shelfModel: ShelfModel

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

    /// The apply run's ledger, or `nil` before one has been started. The review list
    /// reads its marks from here, and the report reads which étagères were created and
    /// which were not from the same place — so the two cannot disagree.
    private(set) var applyProgress: AutoSortApplyProgress?

    /// A session per run rather than one for the app's lifetime: each run is a fresh
    /// question about a collection that may have changed, and a stale transcript
    /// would spend context on the previous library.
    @ObservationIgnored private var session: LanguageModelSession?

    init(
        genreEnrichment: GenreEnrichmentModel,
        shelfModel: ShelfModel,
        errorReporter: AppErrorReporter? = nil
    ) {
        self.genreEnrichment = genreEnrichment
        self.shelfModel = shelfModel
        self.errorReporter = errorReporter
    }

    // MARK: - Availability

    /// Read fresh on every access rather than cached, which is what lets a user switch
    /// Apple Intelligence on and come back to a working feature: `SystemLanguageModel` is
    /// itself observable, so a view reading this in its body re-renders when the system
    /// state changes, with no relaunch and nothing here to invalidate.
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
        case .analysingLibrary, .designingShelves, .sortingGenres, .applying: true
        case .idle, .ready, .failed, .applied: false
        }
    }

    /// Whether the plan on screen can still be approved. False the moment the apply
    /// starts, so a second tap cannot create the same étagères twice — recovery after a
    /// partial failure is a fresh run, never a re-apply of a plan whose books have
    /// since moved.
    var canApply: Bool {
        phase == .ready && (plan?.isEmpty == false)
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
        case .applying: "Création des étagères…"
        case .ready, .failed, .applied: ""
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
        // The previous run's marks go with the previous run's plan. A re-run after a
        // partial failure is a *new* proposal built from what is still unshelved, and
        // showing it the old ledger's ticks would claim étagères it does not contain.
        applyProgress = nil

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

    // MARK: - Applying a plan

    /// Turns the approved plan into real étagères: for each proposed shelf, one
    /// creation and then one membership write, in the order the user reviewed them.
    ///
    /// **This waits rather than being optimistic** — a documented departure from
    /// ADR 0001, alongside the batch scanner's add, and for the same reason: the user
    /// has just approved a large mutation and has to be able to trust what landed.
    /// Eight étagères appearing instantly and then some of them silently vanishing is
    /// the failure being avoided. The two stages are sequenced per shelf rather than run
    /// in parallel because the membership call's argument is the id the creation call
    /// returns; the ledger is updated between them so the user watches progress instead
    /// of one blocking spinner.
    ///
    /// **A failure stops the run and keeps what landed.** No rollback: a rollback that
    /// itself failed mid-way would leave a worse state than a clearly reported partial
    /// one, and `applyProgress` names both halves. Recovery is another run, not a
    /// re-apply — and it is safe because the next plan is built from the books that are
    /// *still* on no étagère, so everything this run filed has stopped being a
    /// candidate. That is what the unshelved-only scoping buys.
    ///
    /// Never throws: the ledger carries what happened and the shared
    /// `AppErrorReporter` carries why.
    func apply(forUser user: User, modelContext: ModelContext) async {
        guard canApply, let plan else { return }

        applyProgress = .init(shelfNames: plan.shelves.map(\.name))
        phase = .applying

        for shelf in plan.shelves {
            applyProgress?.mark(.applying, for: shelf.name)
            do {
                try await apply(shelf: shelf, modelContext: modelContext)
                applyProgress?.mark(.landed, for: shelf.name)
            } catch {
                // Stop here. Every étagère already ticked off stays exactly as it is,
                // and the ones below this one were never created.
                applyProgress?.mark(.failed, for: shelf.name)
                phase = .applied
                errorReporter?.report(error)
                logApplyOutcome()
                return
            }
        }

        phase = .applied
        logApplyOutcome()
    }

    /// One étagère, both stages. Creation first, because its id is the membership
    /// call's argument, and the shelf is only ticked off by the caller once the second
    /// stage has landed too — a tick against a created-but-empty étagère would be the
    /// half-truth this whole waiting design exists to rule out.
    ///
    /// Created private, with no description and no visibility, matching what the shelf
    /// form's defaults produce: the plan proposes a name and a set of books, and
    /// inventing anything else on the user's behalf is not the model's business.
    private func apply(shelf: AutoSortPlan.ProposedShelf, modelContext: ModelContext) async throws {
        let created: Shelf = try await shelfModel.createShelfAwaitingServer(
            name: shelf.name,
            description: "",
            visibility: [],
            modelContext: modelContext
        )

        let items: [InventoryItem] = localItems(ids: shelf.books.map(\.id), modelContext: modelContext)
        // The plan was built from these very items minutes ago, so an empty resolution
        // means the store moved under the run. Failing is honest; filing nothing and
        // ticking the shelf off would leave the user an empty étagère they were told
        // held books.
        guard items.isEmpty == false else { throw AutoSortApplyFailure.booksNoLongerInInventory(shelfName: shelf.name) }

        try await shelfModel.addItemsAwaitingServer(items, to: created, modelContext: modelContext)
    }

    /// Throws the proposal away. Nothing to undo while the plan is only a proposal; once
    /// it has been applied there is still nothing to undo *here*, because what landed is
    /// deliberately kept — an unwanted étagère is deleted from the étagère itself.
    func cancel() {
        plan = nil
        rejections = []
        proposedTaxonomy = []
        applyProgress = nil
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

    /// The stored items behind a proposed étagère's books. `AutoSortBook.id` *is* the
    /// item's server `_id`, which is what makes filing a lookup rather than a match.
    private func localItems(ids: [String], modelContext: ModelContext) -> [InventoryItem] {
        guard ids.isEmpty == false else { return [] }
        let descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { ids.contains($0._id) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
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

    /// What the run actually wrote, so a partial failure can be read from the log as
    /// well as from the screen — the screen is one dismissal away from being gone.
    private func logApplyOutcome() {
        guard let applyProgress else { return }
        switch applyProgress.result {
        case .running:
            break
        case .allLanded:
            print("## Auto-sort applied \(applyProgress.landedCount) étagère(s): \(applyProgress.landedNames.joined(separator: " | "))")
        case .stopped(let landed, let failed, let notAttempted):
            print("## Auto-sort stopped partway — created and filled: \(landed.joined(separator: " | "))")
            print("##   failed on: \(failed.joined(separator: " | "))")
            print("##   never attempted: \(notAttempted.joined(separator: " | "))")
        }
    }
}

/// Why an apply stopped, when the reason is the app's own state rather than the
/// network's. Spelled out rather than folded into `NetworkError` because the user's
/// recovery differs: a network failure is worth retrying now, a library that moved
/// under the run needs a fresh plan.
enum AutoSortApplyFailure: LocalizedError {
    /// The proposed étagère's books are no longer in the local inventory.
    case booksNoLongerInInventory(shelfName: String)

    var errorDescription: String? {
        switch self {
        case .booksNoLongerInInventory(let shelfName):
            "Les livres proposés pour « \(shelfName) » ne sont plus dans votre inventaire."
        }
    }
}
