//
//  SortSessionModel.swift
//  ReCIT_iOS
//
//  The sorting session: the opening sync, the frozen snapshot it produces, and the
//  ordered stack of changes laid on top of it. Everything the screen renders comes
//  back out through `projection`, which is pure.
//
//  **App-scoped**, built in `RootView` and injected like every other model. The apply
//  runs from here, in a task this model owns, and both the writes and the ledger that
//  says what landed outlive the screen: a user who navigates away mid-apply finds the
//  account of it when they come back. The same scoping is why a stack built by
//  dragging survives leaving the screen, which is what the user expects of a draft they
//  have not saved.
//
//  The apply is **awaited, not optimistic** — a documented departure from ADR 0001,
//  reasoned where it happens (`run`). A failure stops the run, keeps what landed, and
//  leaves the rest in the stack, so the pills, the recap and the button labels go on
//  telling the truth with no special case and pressing the button again resumes.
//
//  Being app-scoped makes `load` a *resume* as much as an open — see its note.
//
//  See PRD 0008.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class SortSessionModel {

    enum Phase: Equatable {
        /// The opening sync is running. The screen shows a progress indicator: the
        /// user is about to rearrange their library and must not be doing it against
        /// a stale one.
        case syncing
        /// The snapshot is frozen and the surface is usable.
        case ready
    }

    private(set) var phase: Phase = .syncing

    private(set) var snapshot: SortSnapshot = .empty

    /// The ordered changes laid over the snapshot. Ordered rather than merged, so the
    /// coalescing the write plan does — and any undo — stays a pure function of the
    /// stack alone. Trimmed as the apply lands, so it always holds exactly the work
    /// that is left.
    private(set) var changes: [SortChange] = []

    /// Guards against two appearances of the screen syncing over each other. Not a
    /// phase: a load that is already running is not a state the screen renders
    /// differently, it is a call that must not happen twice.
    private var isLoading: Bool = false

    /// Whether a run is writing right now. Not a `Phase`, because the surface goes on
    /// rendering its sections throughout — the marks ticking down the list *are* the
    /// progress, so a screen that swapped itself for a spinner would hide the one
    /// account the user is watching. What it does withdraw is the escape hatch: the
    /// buttons and the drag both stand down until the run settles.
    private(set) var isApplying: Bool = false

    /// Whether the on-device model is working out a proposal right now. Like
    /// `isApplying` and for the same reason it is not a `Phase`: the sections stay on
    /// screen, because the proposal is about to land *on them* and hiding the library
    /// would hide the thing being rearranged. What stands down is the same escape
    /// hatch — the stack must not grow under a run whose reconciliation was resolved
    /// against the sections as they stood.
    private(set) var isProposing: Bool = false

    /// Whether a run of any kind owns the stack. One question rather than two, so a
    /// guard cannot be written for the apply and forgotten for the proposal.
    var isBusy: Bool { isApplying || isProposing }

    /// How many proposals have landed on the stack. The surface watches it to play the
    /// arrival: a proposal fills several étagères at once, and without motion the screen just
    /// jumps from one library to another (PRD 0009). A counter rather than a flag, so two
    /// proposals in a row are two arrivals.
    private(set) var proposalsLanded: Int = 0

    /// The run's ledger, or `nil` before one has been started. Kept after the run
    /// settles: it is the account of what landed, and a user who left mid-apply has to
    /// find it on their return — which is the whole reason this model is app-scoped.
    private(set) var applyProgress: SortApplyLedger?

    /// The ledger's key for each section the run is writing to. Kept beside the ledger
    /// rather than derived on the fly because a created draft's section id changes
    /// under the run — `.draft(client id)` becomes `.shelf(server id)` — while its row
    /// in the ledger must not.
    private var ledgerKeys: [SortSection.ID: String] = [:]

    /// The run itself, owned by the model rather than by the screen. A user who
    /// navigates away mid-apply leaves the writes going and comes back to the account
    /// of them; a task tied to the view would take both away. Exposed so a caller can
    /// await it.
    @ObservationIgnored private(set) var applyTask: Task<Void, Never>?

    /// What the screen draws. Recomputed on every read rather than cached: it is a
    /// walk over a few hundred books, and a cache is one more thing that can
    /// disagree with the stack.
    var projection: SortProjection {
        .init(snapshot: snapshot, changes: changes)
    }

    /// What applying would do: the operations to send, each étagère's status, and the
    /// counts the recap reads from. Recomputed on every read, like `projection` and for
    /// the same reason — a cached plan is one more thing that can disagree with the
    /// stack, and disagreeing is precisely what a single reduction exists to prevent.
    var writePlan: SortWritePlan {
        .init(snapshot: snapshot, changes: changes)
    }

    /// **The button rule, derived — no "has applied" flag.** A non-empty stack means
    /// the apply button is live and the third button says « Annuler »; an empty one
    /// means the apply button is inert and the third says « Terminer » and closes.
    /// A successful apply empties the stack, so the label changes on its own, and
    /// taking sorting up again changes it back — which is true, because there is once
    /// more something to discard. A sticky flag would leave the screen's only
    /// destructive button labelled « Terminer ».
    var hasPendingChanges: Bool { changes.isEmpty == false }

    /// Opens the session — or resumes the one already in hand.
    ///
    /// **A session with pending changes is resumed, never re-read.** The user left this
    /// screen holding a draft of their library; coming back has to find it exactly as
    /// they left it, and a fresh snapshot underneath a stack built against the old one
    /// would move books out from under changes that named them. With nothing pending
    /// there is nothing to protect, so the library is re-synced and re-frozen — which
    /// is what keeps a second visit from sorting a stale collection.
    ///
    /// Sync failures are reported and swallowed: the store still holds the last known
    /// library, and refusing to open the screen because the network is down would be
    /// worse than sorting a slightly old one — nothing is written here anyway.
    func load(
        user: User,
        shelfModel: ShelfModel,
        inventoryModel: InventoryModel,
        errorReporter: AppErrorReporter?,
        modelContext: ModelContext
    ) async {
        guard isLoading == false else { return }
        // A sync during a run would fight the writes: `ShelfModel`'s membership gate
        // stands the wholesale writers down for the duration of one call, not for the
        // duration of a batch, so a shelf sync landing between two of them would
        // rebuild the whole relation from state the run is halfway through changing.
        // A proposal in flight is re-frozen out from under just as badly: it resolves
        // its names against the sections, and a new snapshot would change them.
        guard isBusy == false else { return }
        guard changes.isEmpty else {
            phase = .ready
            return
        }

        isLoading = true
        phase = .syncing
        defer { isLoading = false }

        // Shelves before inventory: an item resolves its shelf membership against
        // `Shelf` objects that have to exist by then. See ADR 0003.
        do {
            try await shelfModel.syncShelves(forUser: user, modelContext: modelContext)
            try await inventoryModel.syncInventory(forUser: user, modelContext: modelContext)
        } catch {
            errorReporter?.report(error)
        }

        freeze(user: user, modelContext: modelContext)
        phase = .ready
    }

    /// Which names a new étagère may not be given: every section the surface is showing,
    /// existing étagères and drafts alike. Handed to the create form so the refusal
    /// happens while the user is still looking at the field they typed into.
    ///
    /// Read off the projection rather than off the snapshot and the stack separately —
    /// the names the user can see are the names they could confuse, and the projection
    /// is the one place that resolves them.
    var draftNameRule: SortDraftNameRule {
        .init(sections: projection.sections)
    }

    /// Records one étagère created on the spot, and — when a book was dropped onto the tile
    /// that created it — files that book into it in the same movement.
    ///
    /// **Nothing is written**: a draft is a name and a client id until the whole stack is
    /// applied, which is what makes creating an étagère and filling it one gesture (PRD 0008).
    ///
    /// **One call, one set of guards, for both changes.** Splitting it into a create that
    /// returned an id and a move the caller made afterwards would let a caller file a book into
    /// a draft that was refused — a move the projection ignores, so the book would quietly stay
    /// where it was while the screen said otherwise (PRD 0009).
    ///
    /// The naming rule is asked again here even though the form already asked it. Not a second
    /// implementation — the same pure rule, over the same sections — but the stack is what the
    /// pills, the recap and the write are derived from, and a duplicate that reached it would
    /// be applied. A model that trusts its caller to have validated is a model whose invariant
    /// lives in a view.
    func createShelf(named name: String, filling bookId: String? = nil) {
        // Nothing is added to the stack while a run owns it: the plan in flight was reduced
        // from the stack as it stood when the button was pressed, so a draft appended under it
        // would be a section the marks say nothing about — and a draft made under a proposal
        // would be a name it never got to reconcile against.
        guard isBusy == false else { return }
        guard let trimmed = AutoSortName.trimmed(name) else { return }
        guard draftNameRule.accepts(trimmed) else { return }

        // The origin is read off the projection as it stands, which is the same reading the
        // drop was made against. What the pair amounts to is `SortChange.creation`'s rule,
        // pure and asserted there.
        changes.append(
            contentsOf: SortChange.creation(
                draftId: SortDraftID.make(),
                name: trimmed,
                filling: bookId,
                from: bookId.flatMap(section(holding:))
            )
        )
    }

    /// Which section holds a book right now, or `nil` if the projection does not know it.
    private func section(holding bookId: String) -> SortSection.ID? {
        projection.sections.first { section in
            section.books.contains { $0.id == bookId }
        }?.id
    }

    /// Records one drop: the book leaves the section it was dragged from for the one it
    /// was dropped on.
    ///
    /// A book dropped back on the section it came from records **nothing**. A change
    /// that changes nothing would still make the apply button live and turn
    /// « Terminer » into « Annuler » — the screen would be claiming there is work to
    /// discard when there is none. The rule itself lives on `SortChange.move`, which is
    /// pure and therefore assertable; this method only appends what comes back.
    ///
    /// Where the book lands *within* its new section is not this method's business and is
    /// not carried: `SortProjection` puts the books this session moved at the front of
    /// their section, most recent first, so a drop lands on top of the pile by derivation.
    func moveBook(
        _ bookId: String,
        from origin: SortSection.ID,
        to destination: SortSection.ID
    ) {
        // Nothing moves while a run owns the stack. The plan being executed was reduced
        // from the stack as it stood when the button was pressed, so a book pulled out
        // from under it would still be filed by the operation already in flight — and
        // the marks would be describing a library the user had gone on rearranging. A
        // proposal reads the origins it moves books from, so it is no different.
        guard isBusy == false else { return }

        guard let change = SortChange.move(bookId: bookId, from: origin, to: destination) else { return }
        changes.append(change)
    }

    /// Throws the stack away and hands the screen back its snapshot. The other half of
    /// the derived button rule: with a non-empty stack the third button says
    /// « Annuler » and this is what it does.
    ///
    /// The ledger of a run that has already happened is deliberately left alone: those
    /// writes landed, and « Annuler » only ever discards work that was never sent.
    func discardChanges() {
        guard isBusy == false else { return }
        changes = []
    }

    // MARK: - Asking the model

    /// Asks the on-device model for a rangement and lays what it proposes on the stack,
    /// as ordinary changes.
    ///
    /// **The model is one change generator among others.** What comes back is
    /// indistinguishable from a run of drags: it can be adjusted by dragging, « Annuler »
    /// discards it like any other pending work, and it can be asked for again after
    /// sorting by hand. That is what closes the gap PRD 0006 left open, where a plan
    /// could only be accepted or refused whole.
    ///
    /// **It is offered the pile as the screen shows it, not as the store holds it.**
    /// Nothing has been written, so every book the user has filed by hand this session
    /// is still unshelved to the store — asking it would propose them all over again.
    /// The projection is the only thing that knows what is left to do.
    ///
    /// The conversion, reconciliation included, is `SortProposal` and is pure: a name
    /// matching an étagère the user already has — or a draft already on the stack —
    /// becomes a move into it rather than a second shelf of the same name.
    ///
    /// A run that adds nothing says so. From the far side of a wait the user triggered,
    /// a screen that does not change is indistinguishable from a button that does not
    /// work.
    func proposeArrangement(
        user: User,
        autoSortModel: AutoSortModel,
        errorReporter: AppErrorReporter?,
        modelContext: ModelContext
    ) async {
        guard isBusy == false, phase == .ready else { return }

        isProposing = true
        defer { isProposing = false }

        let plan: AutoSortPlan = await autoSortModel.proposePlan(
            forItems: projection.unshelved.books.map(\.id),
            user: user,
            modelContext: modelContext
        )

        // Read after the run rather than before it: nothing can have touched the stack
        // in between — `isProposing` stands every writer down — so this is the same
        // reading, taken at the point it is used.
        let proposal: SortProposal = .init(plan: plan, sections: projection.sections)
        guard proposal.isEmpty == false else {
            errorReporter?.report(SortProposalFailure.nothingToPropose)
            return
        }

        changes.append(contentsOf: proposal.changes)
        proposalsLanded += 1
    }

    // MARK: - Applying

    /// Executes the write plan: the new étagères are created and the books are filed,
    /// one étagère at a time, in the order the screen shows them.
    ///
    /// Returns at once — the run is a **model-owned** `Task`, so leaving the screen
    /// mid-apply neither stops the writes nor loses the account of them.
    ///
    /// A stack that coalesces to nothing is applied too, and empties: there is nothing
    /// to send, but the user pressed a button that promised to save, and leaving a
    /// stack behind would go on offering to discard work that does not exist.
    func apply(
        shelfModel: ShelfModel,
        errorReporter: AppErrorReporter?,
        modelContext: ModelContext
    ) {
        guard isBusy == false, phase == .ready else { return }

        let plan: SortWritePlan = writePlan
        guard plan.hasWork else {
            changes = []
            ledgerKeys = [:]
            applyProgress = .init(entries: [])
            return
        }

        ledgerKeys = .init(
            uniqueKeysWithValues: plan.operations.map { ($0.section, Self.ledgerKey(for: $0.section)) }
        )
        applyProgress = .init(
            entries: plan.operations.map { .init(key: Self.ledgerKey(for: $0.section), name: $0.name) }
        )
        isApplying = true

        applyTask = Task { [weak self] in
            await self?.run(
                plan: plan,
                shelfModel: shelfModel,
                errorReporter: errorReporter,
                modelContext: modelContext
            )
        }
    }

    /// One étagère after another, stopping where it breaks.
    ///
    /// **The writes are awaited, not optimistic.** This is the same documented
    /// departure from ADR 0001 as the auto-sort apply and the batch scanner's add, and
    /// it is deliberate: the user has just approved a whole rearrangement in one
    /// gesture and has to be able to trust what landed. Six étagères filling instantly
    /// and then two of them silently emptying again is a failure mode nobody can see,
    /// whereas six ticks appearing one by one is one they can read. Only single,
    /// user-initiated gestures — the menu's file-this-book, the swipe that takes it off
    /// — stay optimistic. **Do not "fix" this into `OptimisticMutating`.**
    ///
    /// A failure stops the run there and nothing is rolled back: a rollback that itself
    /// failed halfway would leave a worse state than a clearly reported partial one.
    /// What did land has already left the stack (see `land`), so what remains is
    /// exactly the work that is left and pressing the button again resumes it.
    private func run(
        plan: SortWritePlan,
        shelfModel: ShelfModel,
        errorReporter: AppErrorReporter?,
        modelContext: ModelContext
    ) async {
        defer { isApplying = false }

        for write in plan.operations {
            let key: String = Self.ledgerKey(for: write.section)
            applyProgress?.mark(.applying, for: key)
            do {
                try await perform(
                    write,
                    shelfModel: shelfModel,
                    modelContext: modelContext
                )
                // A tick means the creation *and* the membership writes landed. An
                // étagère created but not filled is a failure, not a half-success.
                applyProgress?.mark(.landed, for: key)
            } catch {
                applyProgress?.mark(.failed, for: key)
                errorReporter?.report(error)
                return
            }
        }
    }

    /// One étagère's whole share of the write, in the order the plan grouped it:
    /// create it if it is a draft, then take books off, then put books on.
    ///
    /// **Each call lands on its own.** The creation leaves the stack the instant the
    /// server confirms it, even if the membership write that follows it fails — because
    /// `add-items` drops what a shelf already holds and is therefore safe to send
    /// twice, while a creation is not: replaying one that succeeded would make a second
    /// étagère of the same name. What is left in the stack for a group that broke after
    /// its creation is a plain fill of an étagère that now exists.
    private func perform(
        _ write: SortWritePlan.ShelfWrite,
        shelfModel: ShelfModel,
        modelContext: ModelContext
    ) async throws {
        let shelf: Shelf = try await resolveShelf(
            write,
            shelfModel: shelfModel,
            modelContext: modelContext
        )

        if write.removals.isEmpty == false {
            // Whatever of them the store still knows: a copy that has left the
            // inventory has left the étagère with it, so there is nothing to ask the
            // server to take off.
            try await shelfModel.removeItemsAwaitingServer(
                localItems(ids: write.removals, modelContext: modelContext),
                from: shelf,
                modelContext: modelContext
            )
            land(.booksRemoved(shelfId: shelf._id, bookIds: write.removals))
        }

        if write.additions.isEmpty == false {
            let items: [InventoryItem] = localItems(ids: write.additions, modelContext: modelContext)
            // The snapshot was taken from these very items minutes ago, so resolving
            // none of them means the store moved under the run. Failing is honest;
            // filing nothing and ticking the étagère off would leave the user an
            // étagère they were told held books.
            guard items.isEmpty == false else {
                throw SortApplyFailure.booksNoLongerInInventory(shelfName: write.name)
            }
            try await shelfModel.addItemsAwaitingServer(items, to: shelf, modelContext: modelContext)
            land(.booksAdded(shelfId: shelf._id, bookIds: write.additions))
        }
    }

    /// The étagère this group writes to: created here if it is a draft, looked up in
    /// the store if the server already holds it.
    ///
    /// A created draft's row in the ledger follows it: the section id changes from the
    /// client draft to the server document, and the mark the user is watching must not
    /// go back to unmarked because of it.
    private func resolveShelf(
        _ write: SortWritePlan.ShelfWrite,
        shelfModel: ShelfModel,
        modelContext: ModelContext
    ) async throws -> Shelf {
        switch write.section {
        case .draft(let draftId):
            // Created private, with no description, exactly as the shelf form's
            // defaults produce: the surface asks for a name and a set of books, and
            // inventing anything else on the user's behalf is not its business.
            let created: Shelf = try await shelfModel.createShelfAwaitingServer(
                name: write.name,
                description: "",
                visibility: [],
                modelContext: modelContext
            )
            ledgerKeys[.shelf(created._id)] = Self.ledgerKey(for: write.section)
            land(.shelfCreated(draftId: draftId, shelfId: created._id, name: write.name))
            return created

        case .shelf(let shelfId):
            guard let shelf = localShelf(id: shelfId, modelContext: modelContext) else {
                throw SortApplyFailure.shelfNoLongerExists(shelfName: write.name)
            }
            return shelf

        case .unshelved:
            // The pile is never an operation: a book dropped into it is a removal on
            // the étagère it left, and nothing else. Unreachable by construction, and
            // stated rather than crashed.
            throw SortApplyFailure.shelfNoLongerExists(shelfName: write.name)
        }
    }

    /// Folds one confirmed call back into the session: the snapshot gains what landed
    /// and the stack keeps only what is left. The reduction is pure and lives in
    /// `SortApplyLanding` — which is what makes "the remaining stack is exactly the
    /// unlanded work" assertable without a store.
    private func land(_ confirmation: SortApplyLanding.Confirmation) {
        let landing: SortApplyLanding = .init(
            snapshot: snapshot,
            changes: changes,
            confirmed: confirmation
        )
        snapshot = landing.snapshot
        changes = landing.changes
    }

    /// What one section's row in the ledger is keyed by. The section's identity rather
    /// than its name: two étagères may legitimately share a name — the server does not
    /// enforce uniqueness — and a ledger that collapsed them would tick one off for the
    /// other. A draft's client id is already prefixed, so it cannot collide with a
    /// server document's.
    private static func ledgerKey(for section: SortSection.ID) -> String {
        switch section {
        case .shelf(let id): "shelf:\(id)"
        case .draft(let id): id
        case .unshelved: "unshelved"
        }
    }

    /// What mark one section carries, or `nil` for a section this run has nothing to do
    /// to — which draws no mark at all, because an étagère nobody is writing to should
    /// not look like one that is waiting its turn.
    func applyOutcome(of section: SortSection.ID) -> SortApplyLedger.ShelfOutcome? {
        guard let applyProgress, let key = ledgerKeys[section] else { return nil }
        return applyProgress.outcome(for: key)
    }

    private func localShelf(id: String, modelContext: ModelContext) -> Shelf? {
        let descriptor: FetchDescriptor<Shelf> = .init(predicate: #Predicate { $0._id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func localItems(ids: [String], modelContext: ModelContext) -> [InventoryItem] {
        guard ids.isEmpty == false else { return [] }
        let descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { ids.contains($0._id) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// **Reads SwiftData exactly once, into value types, and never looks again.**
    ///
    /// This is a deliberate departure from ADR 0001, which binds the UI to SwiftData
    /// and keeps it reactive. That rule is right for a screen that *displays* the
    /// library; this one holds a **draft** of it. `ShelfModel`'s membership gate only
    /// stands syncs down while a write is in flight, so across a sorting session
    /// lasting minutes any sync triggered elsewhere — a pull-to-refresh on another
    /// tab, a background refresh — would reassign the whole `Shelf ⇄ InventoryItem`
    /// relation from server state and move books out from under the user's fingers,
    /// undoing gestures they had already made.
    ///
    /// Freezing also makes `SortProjection` a pure function of two value types, which
    /// is what makes the rule "every book is in exactly one section" testable without
    /// a store.
    ///
    /// So: do **not** turn this into a `@Query`. If reactivity is ever wanted here, it
    /// has to arrive as an explicit "the library changed — reload?" affordance, not as
    /// a live binding.
    private func freeze(user: User, modelContext: ModelContext) {
        let ownerId: String = user._id

        let shelfDescriptor: FetchDescriptor<Shelf> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.name)]
        )
        let shelves: [Shelf] = (try? modelContext.fetch(shelfDescriptor)) ?? []

        let itemDescriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.created, order: .reverse)]
        )
        let items: [InventoryItem] = (try? modelContext.fetch(itemDescriptor)) ?? []

        snapshot = .init(
            shelves: shelves.map { shelf in
                .init(
                    id: shelf._id,
                    name: shelf.name,
                    bookIds: shelf.items.map(\._id)
                )
            },
            books: items.map(Self.book(from:))
        )
    }

    /// One copy as the surface needs it. Reuses `AutoSortBook` rather than declaring
    /// a second book value type: the AI proposal (slice 0042) produces an
    /// `AutoSortPlan` over exactly these, so sharing the type is what keeps that
    /// conversion a rename rather than a mapping.
    ///
    /// A copy's genres are the union of the genres of the works behind its edition, in
    /// claim order and deduplicated — the same reading `AutoSortModel` does, so the
    /// genre line under a book says the same thing on both screens.
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
}
