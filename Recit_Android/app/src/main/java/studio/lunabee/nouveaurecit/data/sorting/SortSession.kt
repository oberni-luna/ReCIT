package studio.lunabee.nouveaurecit.data.sorting

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.InventoryRepository
import studio.lunabee.nouveaurecit.data.ShelfRepository
import studio.lunabee.nouveaurecit.data.UserRepository
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfEntity
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity

/**
 * `SortSessionModel`: the « Ranger mes livres » session — the opening sync, the frozen snapshot it
 * produces, and the ordered stack of changes laid over it. Everything the surface renders comes back
 * out of [state] through pure derivations.
 *
 * **App-scoped**, built once in `AppContainer`. The apply runs in [scope], so the writes and the ledger
 * saying what landed outlive the screen: a user who leaves mid-apply finds the account of it on their
 * return. The same scoping is why a stack built by dragging survives leaving the surface.
 *
 * The apply is **awaited, not optimistic** — a documented departure from ADR 0001: the user approved a
 * whole rearrangement in one gesture and has to be able to trust what landed. Six étagères filling
 * instantly and two of them silently emptying again is a failure nobody can see; six ticks appearing one
 * by one is one they can read. **Do not "fix" this into `OptimisticRunner`.**
 *
 * Every method is called from the main thread, as everything in the app's scope is.
 */
class SortSession(
    private val scope: CoroutineScope,
    private val users: UserRepository,
    private val shelves: ShelfRepository,
    private val inventory: InventoryRepository,
    private val db: AppDatabase,
    private val errorReporter: ErrorReporter,
) {
    private val _state: MutableStateFlow<SortSessionState> = MutableStateFlow(SortSessionState())
    val state: StateFlow<SortSessionState> = _state.asStateFlow()

    /**
     * Guards against two openings of the surface syncing over each other. Not a phase: a load already
     * running is not a state the surface renders differently, it is a call that must not happen twice.
     */
    private var isLoading: Boolean = false

    /** The run, owned by the session rather than by the screen, so leaving does not stop the writes. */
    private var applyJob: Job? = null

    /**
     * Bumped by [reset]. A load that was syncing when the user was forgotten must not write the previous
     * user's library back over the fresh state once its sync returns.
     */
    private var generation: Int = 0

    /**
     * Opens the session — or resumes the one already in hand.
     *
     * **A session with pending changes is resumed, never re-read.** The user left holding a draft of their
     * library; a fresh snapshot underneath a stack built against the old one would move books out from
     * under changes that named them. With nothing pending there is nothing to protect, so the library is
     * re-synced and re-frozen — which keeps a second visit from sorting a stale collection.
     *
     * Sync failures are reported and swallowed: the store still holds the last known library, and
     * refusing to open because the network is down would be worse than sorting a slightly old one.
     */
    suspend fun load() {
        if (isLoading) return
        // A sync during a run would rebuild the very memberships the run is halfway through changing.
        if (_state.value.isBusy) return
        if (_state.value.changes.isNotEmpty()) {
            _state.update { it.copy(phase = SortSessionState.Phase.Ready) }
            return
        }

        isLoading = true
        val loadGeneration: Int = generation
        _state.update { it.copy(phase = SortSessionState.Phase.Syncing) }
        try {
            val me: UserEntity? = users.myUser()
            if (me != null) {
                // Shelves before inventory, as `SessionCoordinator` does (ADR 0003).
                try {
                    shelves.syncShelves(me)
                    inventory.syncInventory(users.myUser() ?: me)
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (error: Exception) {
                    errorReporter.report(error)
                }
                val snapshot: SortSnapshot = freeze(me.id)
                if (generation != loadGeneration) return
                _state.update { it.copy(snapshot = snapshot) }
            }
            if (generation != loadGeneration) return
            _state.update { it.copy(phase = SortSessionState.Phase.Ready) }
        } finally {
            isLoading = false
        }
    }

    /**
     * Records one drop: the book leaves the section it sits in for [to].
     *
     * The origin is **resolved against the projection, not trusted from the caller**, and a drop on the
     * section the book already sits in records nothing: a change that changes nothing would still make
     * « Enregistrer » live. Where the book lands *within* its section is the projection's business: the
     * books this session moved come first, so a drop lands on top of the pile by derivation.
     */
    fun moveBook(bookId: String, to: SortSectionId) {
        val current: SortSessionState = _state.value
        // Nothing moves while a run owns the stack: the plan in flight was reduced from the stack as it
        // stood when the button was pressed. Nor before the snapshot is frozen.
        if (current.isBusy || current.phase != SortSessionState.Phase.Ready) return
        val origin: SortSectionId = current.sectionHolding(bookId) ?: return
        val change: SortChange = SortChange.move(bookId, origin, to) ?: return
        val filedFromUnshelved: Boolean = origin == SortSectionId.Unshelved && to != SortSectionId.Unshelved
        _state.update {
            it.copy(
                changes = it.changes + change,
                booksFiledFromUnshelved = it.booksFiledFromUnshelved + if (filedFromUnshelved) 1 else 0,
            )
        }
    }

    /**
     * Records one étagère created on the spot, and — when a book was dropped onto the tile that created
     * it — files that book into it in the same movement. **Nothing is written** until the stack is applied.
     *
     * One call, one set of guards, for both changes: a caller cannot file a book into a draft that was
     * refused. The naming rule is asked again here even though the form asked it: the stack is what gets
     * applied, and a model that trusts its caller to have validated keeps its invariant in a view.
     *
     * @return whether the étagère was accepted.
     */
    fun createShelf(named: String, filling: String? = null): Boolean {
        val current: SortSessionState = _state.value
        if (current.isBusy || current.phase != SortSessionState.Phase.Ready) return false
        val trimmed: String = SortName.trimmed(named) ?: return false
        if (!current.draftNameRule.accepts(trimmed)) return false
        val creation: List<SortChange> = SortChange.creation(
            draftId = SortDraftId.make(),
            name = trimmed,
            filling = filling,
            from = filling?.let(current::sectionHolding),
        )
        _state.update { it.copy(changes = it.changes + creation) }
        return true
    }

    /**
     * Throws the stack away and hands the surface back its snapshot — what « Annuler » does. The ledger of
     * a run that already happened is left alone: those writes landed.
     */
    fun discardChanges() {
        if (_state.value.isBusy) return
        _state.update { it.copy(changes = emptyList()) }
    }

    /**
     * Executes the write plan: new étagères created and books filed, one étagère at a time, in the order
     * the surface shows them. Returns at once — the run belongs to the session's scope.
     *
     * A stack that coalesces to nothing is applied too, and empties: the user pressed a button that
     * promised to save, and leaving a stack behind would go on offering to discard work that does not exist.
     */
    fun apply() {
        val current: SortSessionState = _state.value
        if (current.isBusy || current.phase != SortSessionState.Phase.Ready) return

        val plan: SortWritePlan = current.writePlan
        if (!plan.hasWork) {
            _state.update {
                it.copy(changes = emptyList(), ledgerKeys = emptyMap(), applyProgress = SortApplyLedger(emptyList()))
            }
            return
        }

        _state.update {
            it.copy(
                ledgerKeys = plan.operations.associate { write -> write.section to SortSessionState.ledgerKey(write.section) },
                applyProgress = SortApplyLedger(
                    plan.operations.map { write -> SortApplyLedger.Entry(SortSessionState.ledgerKey(write.section), write.name) },
                ),
                isApplying = true,
            )
        }
        applyJob = scope.launch { run(plan) }
    }

    /**
     * Forgets the session — the draft, the snapshot and the ledger — and stops a run in flight. Called when
     * the user is forgotten, so a different user never opens on a previous user's draft.
     */
    fun reset() {
        generation += 1
        applyJob?.cancel()
        applyJob = null
        _state.value = SortSessionState()
    }

    /**
     * One étagère after another, stopping where it breaks. Nothing is rolled back: a rollback that itself
     * failed halfway would leave a worse state than a clearly reported partial one. What did land has
     * already left the stack ([land]), so pressing the button again resumes.
     */
    private suspend fun run(plan: SortWritePlan) {
        try {
            for (write in plan.operations) {
                val key: String = SortSessionState.ledgerKey(write.section)
                mark(SortApplyLedger.ShelfOutcome.Applying, key)
                try {
                    perform(write)
                    // A tick means the creation *and* the membership writes landed.
                    mark(SortApplyLedger.ShelfOutcome.Landed, key)
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (error: Exception) {
                    mark(SortApplyLedger.ShelfOutcome.Failed, key)
                    errorReporter.report(error)
                    return
                }
            }
        } finally {
            _state.update { it.copy(isApplying = false) }
        }
    }

    /**
     * One étagère's whole share: create it if it is a draft, then take books off, then put books on.
     * **Each call lands on its own**, so a creation leaves the stack the instant it is confirmed, even if
     * the membership write after it fails — replaying it would make a second étagère of the same name.
     */
    private suspend fun perform(write: SortWritePlan.ShelfWrite) {
        val shelfId: String = resolveShelf(write)

        if (write.removals.isNotEmpty()) {
            // Whatever of them the shelf still holds: a copy that left the inventory left the étagère with it.
            shelves.removeItemsNow(shelfId, write.removals)
            land(SortApplyLanding.Confirmation.BooksRemoved(shelfId, write.removals))
        }

        if (write.additions.isNotEmpty()) {
            // The snapshot was taken from these very items minutes ago, so resolving none of them means the
            // store moved under the run. Failing is honest; ticking an empty étagère off is not.
            val known: Set<String> = db.inventoryDao().get(write.additions).map { it.id }.toSet()
            if (known.isEmpty()) throw SortApplyFailure.BooksNoLongerInInventory(write.name)
            shelves.addItemsNow(shelfId, write.additions.filter { it in known })
            land(SortApplyLanding.Confirmation.BooksAdded(shelfId, write.additions))
        }
    }

    /**
     * The étagère a group writes to: created here if it is a draft, looked up in Room if the server holds
     * it. A created draft's ledger row follows it, so the mark the user watches does not go back to unmarked.
     */
    private suspend fun resolveShelf(write: SortWritePlan.ShelfWrite): String = when (val section: SortSectionId = write.section) {
        is SortSectionId.Draft -> {
            val created: ShelfEntity = shelves.createShelfNow(write.name)
            _state.update {
                it.copy(ledgerKeys = it.ledgerKeys + (SortSectionId.Shelf(created.id) to SortSessionState.ledgerKey(section)))
            }
            land(SortApplyLanding.Confirmation.ShelfCreated(section.id, created.id, write.name))
            created.id
        }
        is SortSectionId.Shelf -> db.shelfDao().get(section.id)?.id ?: throw SortApplyFailure.ShelfNoLongerExists(write.name)
        // The pile is never an operation; unreachable by construction, and stated rather than crashed.
        SortSectionId.Unshelved -> throw SortApplyFailure.ShelfNoLongerExists(write.name)
    }

    /** Folds one confirmed call back in: the snapshot gains what landed, the stack keeps only what is left. */
    private fun land(confirmation: SortApplyLanding.Confirmation) {
        _state.update {
            val landing: SortApplyLanding = SortApplyLanding(it.snapshot, it.changes, confirmation)
            it.copy(snapshot = landing.snapshot, changes = landing.changes)
        }
    }

    private fun mark(outcome: SortApplyLedger.ShelfOutcome, key: String) {
        _state.update { it.copy(applyProgress = it.applyProgress?.mark(outcome, key)) }
    }

    /**
     * **Reads Room exactly once, into value types, and never looks again.**
     *
     * A deliberate departure from ADR 0001, which binds screens to the store and keeps them reactive.
     * That is right for a screen that *displays* the library; this one holds a **draft** of it. Across a
     * session lasting minutes, any sync triggered elsewhere would reassign the shelf ⇄ item relation from
     * server state and move books out from under the user's fingers. Freezing also keeps the projection a
     * pure function of two values. Do **not** turn this into a collected `Flow`: if reactivity is ever
     * wanted, it has to arrive as an explicit "the library changed — reload?" affordance.
     */
    private suspend fun freeze(ownerId: String): SortSnapshot {
        val shelfRows: List<ShelfWithItems> = shelves.observeShelvesOf(ownerId).first()
        val items: List<ItemRow> = inventory.observeItemsOf(ownerId).first()
        return SortSnapshot(
            shelves = shelfRows.map { row ->
                SortSnapshot.Shelf(id = row.shelf.id, name = row.shelf.name, bookIds = row.items.map { it.item.id })
            },
            books = items.map(::book),
        )
    }

    private fun book(row: ItemRow): SortBook = SortBook(
        id = row.item.id,
        title = row.title,
        authors = row.authorNames.joinToString(", "),
        coverImageUrl = row.image,
    )
}
