package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortApplyLedger`: one outcome per étagère the apply run writes to, and the reduction the report is
 * written from.
 *
 * Pure because a partial failure makes its two questions load-bearing. *Is this étagère done* decides
 * the mark drawn against it, and an étagère whose shelf was created but whose books never landed must
 * not be shown as done. *Which étagères landed and which did not* is the report, and since nothing is
 * rolled back it is the user's only account of their library — in three parts rather than two,
 * because the étagère the run broke on may exist without its books.
 *
 * Immutable: [mark] returns a new ledger, so it sits in a `StateFlow` as a plain value. Declaration
 * order is kept throughout, so the report names étagères in the order the user was reading them.
 *
 * **An entry is keyed apart from its name.** Two étagères may share a name — the server does not
 * enforce uniqueness — and a draft becoming a real étagère mid-run changes the section's id but not its
 * row. So an entry carries a stable [Entry.key] beside the [Entry.name] the report reads out.
 */
data class SortApplyLedger private constructor(
    /** The étagères of the run, in the order they will be written. */
    val entries: List<Entry>,
    private val outcomes: Map<String, ShelfOutcome>,
) {
    /**
     * How far one étagère has got. [Landed] means *both* stages landed — the shelf exists and its books
     * are on it — because the whole point of waiting is that a tick can be trusted.
     */
    enum class ShelfOutcome {
        /** Not attempted: the run has not reached it, or stopped before it. */
        Pending,
        Applying,
        Landed,
        Failed,
    }

    /** Where the run as a whole stands. Reduced rather than tracked, so it never disagrees with the marks. */
    sealed interface Result {
        data object Running : Result

        data object AllLanded : Result

        /**
         * Stopped partway, nothing rolled back. [landed] exists and holds its books; [failed] is where
         * the run broke, and may exist empty; [notAttempted] was never touched. Folding [failed] into
         * "not created" would send the user looking for an étagère already in their carousel.
         */
        data class Stopped(val landed: List<String>, val failed: List<String>, val notAttempted: List<String>) : Result
    }

    /** One étagère of the run: what identifies it while the run goes, and what the report calls it. */
    data class Entry(val key: String, val name: String) {
        /** The étagère whose name *is* its identity. */
        constructor(name: String) : this(key = name, name = name)
    }

    /** The étagères of the run, named, in the order they will be written. */
    val shelfNames: List<String> get() = entries.map { it.name }

    /** An étagère the ledger does not know reads as pending: a row it has no record of has not been done. */
    fun outcome(key: String): ShelfOutcome = outcomes[key] ?: ShelfOutcome.Pending

    /**
     * A copy recording [outcome] for [key]. An unknown key changes nothing — the ledger is built from the
     * plan being applied, so inventing a row would put an étagère on screen that was never planned.
     */
    fun mark(outcome: ShelfOutcome, key: String): SortApplyLedger =
        if (key !in outcomes) this else copy(outcomes = outcomes + (key to outcome))

    /** The étagères that exist and hold their books, in order. */
    val landedNames: List<String> get() = names(ShelfOutcome.Landed)

    /** Where the run broke. At most one, since the run stops there. */
    val failedNames: List<String> get() = names(ShelfOutcome.Failed)

    /** The étagères the run never got to, in order. */
    val notAttemptedNames: List<String> get() = names(ShelfOutcome.Pending)

    /** Everything that did not land, however — what decides whether the run is over. Not the report's reading. */
    val notLandedNames: List<String> get() = entries.filter { outcome(it.key) != ShelfOutcome.Landed }.map { it.name }

    val landedCount: Int get() = landedNames.size

    /** An empty ledger is [Result.AllLanded], not running: nothing to do and nothing failed is a finished run. */
    val result: Result
        get() {
            val failed: List<String> = failedNames
            return when {
                failed.isNotEmpty() -> Result.Stopped(landedNames, failed, notAttemptedNames)
                notLandedNames.isEmpty() -> Result.AllLanded
                else -> Result.Running
            }
        }

    val isFinished: Boolean get() = result != Result.Running

    private fun names(matching: ShelfOutcome): List<String> = entries.filter { outcome(it.key) == matching }.map { it.name }

    companion object {
        /** Duplicates are collapsed on the way in, so [entries] and the outcomes cannot disagree on a count. */
        operator fun invoke(entries: List<Entry>): SortApplyLedger {
            val ordered: List<Entry> = entries.distinctBy { it.key }
            return SortApplyLedger(ordered, ordered.associate { it.key to ShelfOutcome.Pending })
        }
    }
}
