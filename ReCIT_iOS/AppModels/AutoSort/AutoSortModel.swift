//
//  AutoSortModel.swift
//  ReCIT_iOS
//
//  Owns the on-device session and runs the three phases that turn a collection's genres
//  into a proposed set of étagères. The impure half of auto-sort: the store and the
//  language model live here, and the three pieces that can be got wrong — the histogram,
//  the validator, the assignment — live in `Model/AutoSort` as pure value types this
//  only calls.
//
//  **It writes nothing at all.** It owned a review screen, an apply and a ledger until
//  PRD 0008; the sorting surface replaced all three, so what is left is the pipeline and
//  `proposePlan`, which hands a plan back to its caller instead of publishing one. The
//  app now has exactly one implementation of "create étagères and fill them", and it is
//  `SortSessionModel`. Nothing here has a phase, a plan or a ledger to show, because
//  nothing here has a screen.
//
//  The model never sees a book. Phase 1 is shown genres and counts, phase 2 is shown
//  genres and étagère names, phase 3 is arithmetic. That is what keeps a
//  three-thousand-book library the same cost as a three-hundred-book one — the call
//  count grows with distinct genres, never with books.
//
//  See PRD 0006 and PRD 0008.
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

    init(
        genreEnrichment: GenreEnrichmentModel,
        errorReporter: AppErrorReporter? = nil
    ) {
        self.genreEnrichment = genreEnrichment
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

    // MARK: - Proposing an arrangement

    /// Runs the three phases over a set of copies the caller names, and hands the plan
    /// back. **Writes nothing** — not the plan, not the étagères, not a single field.
    ///
    /// **The caller chooses the collection.** The sorting surface holds a frozen
    /// snapshot with a stack of unsaved drags on top of it, so "the books on no étagère"
    /// is a question only its projection can answer — the store still has every one of
    /// them unshelved. Asking the store would propose again for books the user has just
    /// filed by hand.
    ///
    /// **And it publishes nothing.** A proposal is a value the caller lays on its own
    /// stack, where it becomes ordinary changes the user can adjust or discard. That is
    /// what closes the gap PRD 0006 left open, where a plan could only be accepted or
    /// refused whole — and it is why this model no longer needs a phase, a stored plan
    /// or a ledger.
    ///
    /// A session per call rather than one for the model's lifetime: each call is a fresh
    /// question about a collection that may have changed, and a stale transcript would
    /// spend context on the previous library.
    ///
    /// Never throws. A failure is reported through the shared `AppErrorReporter` and
    /// comes back as a plan that proposes nothing, which the caller lays on its stack as
    /// no changes at all.
    ///
    /// Runs on-device throughout. No part of the library is sent anywhere.
    func proposePlan(
        forItems itemIds: [String],
        user: User,
        modelContext: ModelContext
    ) async -> AutoSortPlan {
        // The genre backfill first: the whole design rests on genre data, and this is
        // its only caller. Idempotent, so a second run costs nothing. It covers the
        // works of unshelved copies — which is every copy the surface can offer here,
        // bar one the user has just dragged *off* an étagère.
        await genreEnrichment.enrichUnshelvedWorks(forUser: user, modelContext: modelContext)

        // Read after the backfill, never before: the snapshot the surface froze on
        // arrival carries the genres of the moment it was taken, and on a first run that
        // is none of them.
        let books: [AutoSortBook] = booksInOrder(ids: itemIds, modelContext: modelContext)
        let histogram: GenreHistogram = .init(books: books)

        // No genre anywhere is a real outcome, not a failure: these books stay where
        // they are rather than being guessed at from title and author.
        guard histogram.isEmpty == false else { return .init(nothingToPropose: books) }

        do {
            let session: LanguageModelSession = .init(instructions: AutoSortPrompts.instructions)
            let taxonomy: [String] = try await proposeTaxonomy(session: session, histogram: histogram)
            let assignments: [ShelfMappingValidator.RawAssignment] = try await mapGenres(
                session: session,
                taxonomy: taxonomy,
                histogram: histogram
            )
            let mapping: ValidatedGenreMapping = try ShelfMappingValidator.validate(
                taxonomy: taxonomy,
                assignments: assignments,
                offeredGenres: histogram.genres
            )
            logOutcome(mapping: mapping, histogram: histogram)
            return .init(mapping: mapping, books: books)
        } catch {
            errorReporter?.report(error)
            return .init(nothingToPropose: books)
        }
    }

    /// The named copies, in the order they were named. The caller's order is the order
    /// the user is reading them in on screen, and a fetch answers in its own.
    private func booksInOrder(ids: [String], modelContext: ModelContext) -> [AutoSortBook] {
        let items: [InventoryItem] = localItems(ids: ids, modelContext: modelContext)
        var booksById: [String: AutoSortBook] = [:]
        for item in items {
            booksById[item._id] = Self.book(from: item)
        }
        return ids.compactMap { booksById[$0] }
    }

    // MARK: - Phase 1

    /// The histogram is passed rather than read off `self`, which is what keeps a run
    /// free of state: two callers could ask at once and neither would see the other's
    /// collection.
    private func proposeTaxonomy(
        session: LanguageModelSession,
        histogram: GenreHistogram
    ) async throws -> [String] {
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
        taxonomy: [String],
        histogram: GenreHistogram
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

    /// One stored copy as every phase of the pipeline needs it.
    ///
    /// A copy's genres are the union of the genres of the works behind its edition, in
    /// claim order and deduplicated; `AutoSortBook.primaryGenre` then decides which
    /// single one it is filed under.
    private static func book(from item: InventoryItem) -> AutoSortBook {
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

    /// The stored items behind a set of proposed books. `AutoSortBook.id` *is* the
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
    /// traces rather than being inferred from the screen — which no longer shows them
    /// at all, the proposal having become ordinary changes on someone else's stack.
    private func logOutcome(mapping: ValidatedGenreMapping, histogram: GenreHistogram) {
        print("## Auto-sort taxonomy: \(mapping.shelfNames.joined(separator: " | "))")
        print("## Auto-sort mapped \(mapping.shelfByGenreKey.count)/\(histogram.entries.count) genre(s), \(mapping.rejections.count) rejected, \(mapping.unmappedGenres.count) unmapped")
        for rejection in mapping.rejections {
            print("##   rejected: \(rejection)")
        }
    }
}
