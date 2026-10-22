package studio.lunabee.nouveaurecit.data.sorting

/**
 * What [SortSession] holds, as one immutable value in a `StateFlow` — the observable half of iOS's
 * `SortSessionModel`.
 *
 * Everything the surface draws is derived from [snapshot] and [changes]: [projection], [writePlan],
 * [draftNameRule], [footer]. Derived per state rather than tracked beside it, so a pill, a recap and
 * a write cannot disagree. The derivations are computed once per state, on first read.
 */
data class SortSessionState(
    val phase: Phase = Phase.Syncing,
    val snapshot: SortSnapshot = SortSnapshot.Empty,
    /**
     * The ordered changes laid over the snapshot. Ordered rather than merged, so coalescing stays a pure
     * function of the stack. Trimmed as an apply lands, so it always holds exactly the work that is left.
     */
    val changes: List<SortChange> = emptyList(),
    /**
     * Whether a run is writing right now. Not a [Phase]: the surface keeps rendering its sections — the
     * marks ticking down *are* the progress — and only the buttons and the drag stand down.
     */
    val isApplying: Boolean = false,
    /**
     * The run's ledger, or `null` before one has been started. Kept after the run settles: it is the
     * account of what landed, and a user who left mid-apply has to find it on their return.
     */
    val applyProgress: SortApplyLedger? = null,
    /**
     * The ledger's key for each section the run writes to. Kept rather than derived because a created
     * draft's section id changes under the run — `Draft(client id)` becomes `Shelf(server id)` — while
     * its row in the ledger must not.
     */
    val ledgerKeys: Map<SortSectionId, String> = emptyMap(),
    /**
     * How many books this session has taken out of « Livres à ranger » and filed onto an étagère. Only
     * accepted moves count: a drop that records no change taught nothing.
     */
    val booksFiledFromUnshelved: Int = 0,
) {
    enum class Phase {
        /** The opening sync is running: the user must not rearrange a stale library. */
        Syncing,

        /** The snapshot is frozen and the surface is usable. */
        Ready,
    }

    /** What the screen draws. */
    val projection: SortProjection by lazy { SortProjection(snapshot, changes) }

    /** What applying would do: the operations, each étagère's status, the recap's counts. */
    val writePlan: SortWritePlan by lazy { SortWritePlan(snapshot, changes) }

    /**
     * **The button rule, derived — no "has applied" flag.** A non-empty stack makes « Enregistrer » and
     * « Annuler » live; a successful apply empties the stack, so they stand down on their own.
     */
    val hasPendingChanges: Boolean get() = changes.isNotEmpty()

    /** Whether a run owns the stack. Every writer stands down while it does. */
    val isBusy: Boolean get() = isApplying

    /** Which names a new étagère may not be given: every section on screen, étagères and drafts alike. */
    val draftNameRule: SortDraftNameRule by lazy { SortDraftNameRule(projection.sections) }

    /** The footer's reading. Drafts count as étagères: one accepts drops the moment it exists. */
    val footer: SortFooter
        get() = SortFooter.of(writePlan, applyProgress, hasShelves = projection.sections.any { !it.isUnshelved })

    /** Which section holds [bookId] right now, or `null` if the projection does not know it. */
    fun sectionHolding(bookId: String): SortSectionId? =
        projection.sections.firstOrNull { section -> section.books.any { it.id == bookId } }?.id

    /**
     * What mark [section] carries, or `null` for a section this run has nothing to do to — which draws no
     * mark at all, because an étagère nobody is writing to should not look like one waiting its turn.
     */
    fun applyOutcome(section: SortSectionId): SortApplyLedger.ShelfOutcome? {
        val progress: SortApplyLedger = applyProgress ?: return null
        val key: String = ledgerKeys[section] ?: return null
        return progress.outcome(key)
    }

    companion object {
        /**
         * What one section's row in the ledger is keyed by: its identity rather than its name, since two
         * étagères may share a name. A draft's client id is already prefixed, so it cannot collide.
         */
        fun ledgerKey(section: SortSectionId): String = when (section) {
            is SortSectionId.Shelf -> "shelf:${section.id}"
            is SortSectionId.Draft -> section.id
            SortSectionId.Unshelved -> "unshelved"
        }
    }
}
