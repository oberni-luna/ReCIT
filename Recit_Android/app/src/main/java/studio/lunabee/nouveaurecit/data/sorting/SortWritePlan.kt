package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortWritePlan`: snapshot + change stack → what « Enregistrer » would do.
 *
 * **One reduction, three readings.** [operations] is what gets sent, [status] is what each étagère's
 * pill says, [summary] is what the recap sentence is built from. Three views of a single pass, so a
 * pill cannot claim an étagère changed while the write leaves it alone.
 *
 * **The reduction is a diff of two projections** — the library as the snapshot holds it, and as the
 * stack leaves it. The projection owns the rule that a book sits in exactly one section; a plan that
 * partitioned the books a second time by hand would eventually partition them differently from the
 * screen. Coalescing falls out of the diff: a book moved three times is one removal and one addition,
 * and a book taken off and put back is nothing at all.
 *
 * Two rules stated rather than left implicit:
 * - **A draft is created whether or not it ends up holding books.** Naming an étagère is the
 *   instruction; filling it is a separate one (iOS `docs/features/0009`).
 * - **An étagère emptied by dragging is modified, never deleted.** A drag does not delete a shelf
 *   behind the user's back.
 */
data class SortWritePlan private constructor(
    /** What applying sends, one group per étagère, in the order the screen shows them. */
    val operations: List<ShelfWrite>,
    val summary: Summary,
    /**
     * Whether the user has done anything at all, as opposed to whether it amounts to anything. The two
     * differ exactly when the stack coalesces to nothing, and the recap has to tell those apart.
     */
    val hasPendingChanges: Boolean,
    private val statuses: Map<SortSectionId, ShelfStatus>,
) {
    /** Which side of the pending work one étagère is on — the pill. Absence carries the normal state. */
    enum class ShelfStatus {
        /** Exists on the server, and applying would not touch it. No pill. */
        Untouched,

        /** Does not exist on the server yet. « Nouvelle ». A draft left empty is new like any other. */
        New,

        /** Exists on the server and its contents have changed. « Modifiée ». */
        Modified,
    }

    /**
     * One étagère's whole share of the write, in the order it has to be sent: create it if it is a
     * draft, then take books off, then put books on.
     *
     * **Removals before additions**, so a book is never on two étagères even momentarily. If a removal
     * lands and the matching addition does not, the book falls back into the pile — an honest
     * intermediate state, never a lost book.
     */
    data class ShelfWrite(
        /** [SortSectionId.Shelf] for an étagère the server holds, [SortSectionId.Draft] for one to create first. */
        val section: SortSectionId,
        /** What a draft is created under, and what a mark or a failure report names it by. */
        val name: String,
        /** Whether the étagère has to be brought into existence first: true for exactly the drafts. */
        val createsShelf: Boolean,
        /** Inventory item `_id`s to take off this étagère, in snapshot order. */
        val removals: List<String>,
        /** Inventory item `_id`s to file onto it, in snapshot order. */
        val additions: List<String>,
    ) {
        val id: SortSectionId get() = section
    }

    /**
     * The counts the recap sentence is built from — four numbers rather than a string, because the
     * sentence is copy and copy lives in the string resources with its plurals.
     */
    data class Summary(
        /** Drafts that will be created — every one of them, filled or not. */
        val shelvesToCreate: Int,
        /** Étagères that already exist and whose contents change. */
        val shelvesModified: Int,
        /** Books that end up on an étagère they were not on. A book dropped into the pile is not filed. */
        val booksFiled: Int,
        /** Books still on no étagère once this is applied: the one count that describes the result. */
        val booksLeftUnshelved: Int,
    ) {
        /** One clause of the recap sentence. A clause exists only when its count does. */
        sealed interface Clause {
            data class ShelvesToCreate(val count: Int) : Clause
            data class ShelvesModified(val count: Int) : Clause
            data class BooksFiled(val count: Int) : Clause
            data class BooksLeftUnshelved(val count: Int) : Clause
        }

        /**
         * The clauses to say, in the one order they are said — from the work to its result — with the
         * zeros left out. Empty for a stack that coalesces to nothing *and* leaves no book unshelved;
         * the recap gates on [SortWritePlan.hasWork], not on this being empty.
         */
        val clauses: List<Clause>
            get() = buildList {
                if (shelvesToCreate > 0) add(Clause.ShelvesToCreate(shelvesToCreate))
                if (shelvesModified > 0) add(Clause.ShelvesModified(shelvesModified))
                if (booksFiled > 0) add(Clause.BooksFiled(booksFiled))
                if (booksLeftUnshelved > 0) add(Clause.BooksLeftUnshelved(booksLeftUnshelved))
            }
    }

    /** What one section's pill says. Unknown sections — and the pile — are untouched. */
    fun status(of: SortSectionId): ShelfStatus = statuses[of] ?: ShelfStatus.Untouched

    /** Whether applying would send anything. False for an untouched library and for a stack that cancels itself out. */
    val hasWork: Boolean get() = operations.isNotEmpty()

    companion object {
        operator fun invoke(snapshot: SortSnapshot, changes: List<SortChange> = emptyList()): SortWritePlan {
            val before: SortProjection = SortProjection(snapshot)
            val after: SortProjection = SortProjection(snapshot, changes)

            val booksBefore: Map<SortSectionId, List<String>> = before.sections.associate { section ->
                section.id to section.books.map { it.id }
            }

            // **What gets sent must not depend on how the screen arranged itself.** Sections read in
            // arrival order; every operation's ids are put back into snapshot order so the payload is a
            // function of the membership the gestures add up to, not of the gestures.
            val rankOfBook: Map<String, Int> = snapshot.books.withIndex().associate { (index, book) -> book.id to index }
            val bySnapshotRank: Comparator<String> = compareBy { rankOfBook[it] ?: Int.MAX_VALUE }

            val operations: MutableList<ShelfWrite> = mutableListOf()
            val statuses: MutableMap<SortSectionId, ShelfStatus> = hashMapOf()

            // The pile is skipped: a book dropped into it is a removal on the étagère it left, and nothing else.
            for (section in after.sections) {
                if (section.isUnshelved) continue
                val had: List<String> = booksBefore[section.id].orEmpty()
                val has: List<String> = section.books.map { it.id }
                val hadIds: Set<String> = had.toSet()
                val hasIds: Set<String> = has.toSet()

                val removals: List<String> = had.filter { it !in hasIds }.sortedWith(bySnapshotRank)
                val additions: List<String> = has.filter { it !in hadIds }.sortedWith(bySnapshotRank)

                val isDraft: Boolean = section.id is SortSectionId.Draft
                if (isDraft) {
                    // Always an operation, even with nothing under it: the user named an étagère.
                    statuses[section.id] = ShelfStatus.New
                } else {
                    val isTouched: Boolean = removals.isNotEmpty() || additions.isNotEmpty()
                    statuses[section.id] = if (isTouched) ShelfStatus.Modified else ShelfStatus.Untouched
                    if (!isTouched) continue
                }

                operations.add(
                    ShelfWrite(
                        section = section.id,
                        name = section.name.orEmpty(),
                        createsShelf = isDraft,
                        removals = removals,
                        additions = additions,
                    ),
                )
            }

            return SortWritePlan(
                operations = operations,
                summary = Summary(
                    shelvesToCreate = operations.count { it.createsShelf },
                    shelvesModified = operations.count { !it.createsShelf },
                    booksFiled = operations.sumOf { it.additions.size },
                    booksLeftUnshelved = after.unshelved.books.size,
                ),
                hasPendingChanges = changes.isNotEmpty(),
                statuses = statuses,
            )
        }
    }
}
