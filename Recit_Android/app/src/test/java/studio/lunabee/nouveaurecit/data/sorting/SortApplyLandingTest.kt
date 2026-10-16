package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `SortApplyLandingTests`: what the surface looks like once part of a rangement has been written, and
 * what pressing « Enregistrer » again would send. A failure halfway stops the run, keeps what landed and
 * leaves the rest in the stack — so resuming repeats nothing. Repeating is not cosmetic: replaying a
 * creation that succeeded leaves the user with two étagères of the same name.
 *
 * The runs drive [SortApplyLanding] exactly as [SortSession] does — one landing per confirmed call —
 * against a stub that hands back an id for every creation and can be told to break at the *n*th call.
 */
class SortApplyLandingTest {
    private val s1: SortSectionId = SortSectionId.Shelf("s1")
    private val s2: SortSectionId = SortSectionId.Shelf("s2")
    private val s3: SortSectionId = SortSectionId.Shelf("s3")
    private val pile: SortSectionId = SortSectionId.Unshelved
    private val sf: SortSectionId = SortSectionId.Draft("draft:sf")

    private fun book(id: String): SortBook = SortBook(id = id, title = "Livre $id")

    /** Two étagères holding books, one empty étagère, and two books on none. */
    private val library: SortSnapshot = SortSnapshot(
        shelves = listOf(
            SortSnapshot.Shelf("s1", "Romans classiques", listOf("1", "2")),
            SortSnapshot.Shelf("s2", "Poésie", listOf("3")),
            SortSnapshot.Shelf("s3", "Bandes dessinées", emptyList()),
        ),
        books = listOf(book("1"), book("2"), book("3"), book("4"), book("5")),
    )

    private fun move(bookId: String, from: SortSectionId, to: SortSectionId): SortChange = SortChange.MoveBook(bookId, from, to)

    /**
     * One apply, against a server that answers everything except — optionally — the *n*th call. The plan
     * is reduced once, at the start, and each confirmed call is folded back in on its own.
     */
    private class Run(var snapshot: SortSnapshot, var changes: List<SortChange>) {
        /** The names the server was asked to create, in order. */
        val creations: MutableList<String> = mutableListOf()

        /** The `remove-items` calls, as (étagère id, books). */
        val removals: MutableList<Pair<String, List<String>>> = mutableListOf()

        /** The `add-items` calls, as (étagère id, books). */
        val additions: MutableList<Pair<String, List<String>>> = mutableListOf()

        private var calls: Int = 0

        val plan: SortWritePlan get() = SortWritePlan(snapshot, changes)
        val projection: SortProjection get() = SortProjection(snapshot, changes)

        /** Runs the apply. [failingAtCall] counts every server call, creations included, from 1. */
        fun apply(failingAtCall: Int? = null): List<String> {
            val landed: MutableList<String> = mutableListOf()
            for (write in plan.operations) {
                var shelfId: String = (write.section as? SortSectionId.Shelf)?.id.orEmpty()

                if (write.createsShelf) {
                    val draft: SortSectionId.Draft = write.section as? SortSectionId.Draft ?: continue
                    calls += 1
                    if (calls == failingAtCall) return landed
                    creations.add(write.name)
                    shelfId = "server-${creations.size}"
                    land(SortApplyLanding.Confirmation.ShelfCreated(draft.id, shelfId, write.name))
                }
                if (write.removals.isNotEmpty()) {
                    calls += 1
                    if (calls == failingAtCall) return landed
                    removals.add(shelfId to write.removals)
                    land(SortApplyLanding.Confirmation.BooksRemoved(shelfId, write.removals))
                }
                if (write.additions.isNotEmpty()) {
                    calls += 1
                    if (calls == failingAtCall) return landed
                    additions.add(shelfId to write.additions)
                    land(SortApplyLanding.Confirmation.BooksAdded(shelfId, write.additions))
                }
                landed.add(write.name)
            }
            return landed
        }

        private fun land(confirmation: SortApplyLanding.Confirmation) {
            val landing: SortApplyLanding = SortApplyLanding(snapshot, changes, confirmation)
            snapshot = landing.snapshot
            changes = landing.changes
        }
    }

    private fun section(projection: SortProjection, name: String): SortSection? = projection.sections.firstOrNull { it.name == name }

    private fun idsOf(projection: SortProjection, name: String): List<String>? = section(projection, name)?.books?.map { it.id }

    // A run that finishes

    /** The end of a successful rangement: nothing left to save, so the recap goes quiet and the pills go out. */
    @Test
    fun aCompleteRunEmptiesTheStack() {
        val run: Run = Run(library, listOf(SortChange.CreateShelf("draft:sf", "Science-fiction"), move("4", pile, sf), move("1", s1, s2)))

        run.apply()

        assertTrue(run.changes.isEmpty())
        assertFalse(run.plan.hasWork)
        assertFalse(run.plan.hasPendingChanges)
        assertEquals(SortWritePlan.ShelfStatus.Untouched, run.plan.status(s1))
        assertEquals(SortWritePlan.ShelfStatus.Untouched, run.plan.status(s2))
    }

    /** What it wrote is what the user arranged. */
    @Test
    fun aCompleteRunLandsTheArrangement() {
        val run: Run = Run(library, listOf(SortChange.CreateShelf("draft:sf", "Science-fiction"), move("4", pile, sf), move("1", s1, s2)))

        run.apply()

        assertEquals(listOf("Science-fiction"), run.creations)
        assertEquals(listOf("4"), idsOf(run.projection, "Science-fiction"))
        assertEquals(listOf("2"), idsOf(run.projection, "Romans classiques"))
        // Snapshot order, not arrival order: the stack is empty, so nothing is "moved" any more.
        assertEquals(listOf("1", "3"), idsOf(run.projection, "Poésie"))
        assertEquals(listOf("5"), run.projection.unshelved.books.map { it.id })
    }

    /** A draft left empty is created like any other, and the stack still empties afterwards. */
    @Test
    fun anEmptyDraftIsCreatedByTheRun() {
        val run: Run = Run(library, listOf(SortChange.CreateShelf("draft:essais", "Essais"), move("4", pile, s3)))
        assertEquals(1, run.plan.summary.shelvesToCreate)

        run.apply()

        assertEquals(listOf("Essais"), run.creations)
        assertTrue(run.changes.isEmpty())
        assertEquals(emptyList<String>(), idsOf(run.projection, "Essais"))
    }

    /** A book dragged about all afternoon costs the server one removal and one addition. */
    @Test
    fun aBookMovedThreeTimesIsWrittenOnce() {
        val run: Run = Run(library, listOf(move("1", s1, s2), move("1", s2, pile), move("1", pile, s3)))

        run.apply()

        assertEquals(listOf("s1" to listOf("1")), run.removals)
        assertEquals(listOf("s3" to listOf("1")), run.additions)
    }

    // A run that stops partway

    /** What the run already wrote has left the stack; what is left is exactly the work that did not happen. */
    @Test
    fun aStopLeavesOnlyTheUnlandedWork() {
        val run: Run = Run(library, listOf(move("1", s1, pile), move("4", pile, s3)))

        // Call 1 is « Romans classiques » giving up its book; call 2 is « Bandes dessinées » receiving one.
        run.apply(failingAtCall = 2)

        assertEquals(SortWritePlan.ShelfStatus.Untouched, run.plan.status(s1))
        assertEquals(SortWritePlan.ShelfStatus.Modified, run.plan.status(s3))
        assertEquals(1, run.plan.operations.size)
        assertEquals(s3, run.plan.operations.first().section)
        assertEquals(listOf("4"), run.plan.operations.first().additions)
        assertTrue(run.plan.hasPendingChanges)
    }

    /** If the addition of a move fails, the book falls back into « À ranger » — never on two, never lost. */
    @Test
    fun aMoveThatBreaksBetweenItsHalvesLeavesTheBookInThePile() {
        val run: Run = Run(library, listOf(move("1", s1, s2)))

        run.apply(failingAtCall = 2)

        val saved: SortProjection = SortProjection(run.snapshot)
        assertTrue("1" in saved.unshelved.books.map { it.id })
        assertEquals(listOf("2"), idsOf(saved, "Romans classiques"))
        assertEquals(listOf("3"), idsOf(saved, "Poésie"))

        // The half that did not happen is still on screen, still pending.
        assertEquals(1, run.plan.operations.size)
        assertEquals(s2, run.plan.operations.first().section)
        assertEquals(listOf("1"), run.plan.operations.first().additions)
        assertEquals(listOf("1", "3"), idsOf(run.projection, "Poésie"))
    }

    /** The creation landed and the books did not: what is left is a fill, never a second creation. */
    @Test
    fun aCreationThatLandedIsNotReplayed() {
        val run: Run = Run(library, listOf(SortChange.CreateShelf("draft:sf", "Science-fiction"), move("4", pile, sf), move("5", pile, sf)))

        // Call 1 creates the étagère, call 2 files its books and fails.
        run.apply(failingAtCall = 2)

        assertEquals(listOf("Science-fiction"), run.creations)
        assertEquals(1, run.plan.operations.size)
        assertFalse(run.plan.operations.first().createsShelf)
        assertEquals(listOf("4", "5"), run.plan.operations.first().additions)
        assertEquals(SortWritePlan.ShelfStatus.Modified, run.plan.status(SortSectionId.Shelf("server-1")))

        run.apply()

        assertEquals(listOf("Science-fiction"), run.creations)
        assertTrue(run.changes.isEmpty())
    }

    /** Pressing again finishes the rangement, and the server hears about each piece of work exactly once. */
    @Test
    fun resumingFinishesWithoutRepeating() {
        val changes: List<SortChange> = listOf(
            SortChange.CreateShelf("draft:sf", "Science-fiction"),
            move("4", pile, sf),
            move("1", s1, s2),
            move("3", s2, pile),
        )
        val straightThrough: Run = Run(library, changes)
        straightThrough.apply()

        val interrupted: Run = Run(library, changes)
        interrupted.apply(failingAtCall = 3)
        assertTrue(interrupted.changes.isNotEmpty())
        interrupted.apply()

        assertTrue(interrupted.changes.isEmpty())
        assertEquals(straightThrough.creations, interrupted.creations)
        assertEquals(straightThrough.removals.map { it.second }, interrupted.removals.map { it.second })
        assertEquals(straightThrough.additions.map { it.second }, interrupted.additions.map { it.second })
        assertEquals(straightThrough.snapshot, interrupted.snapshot)
    }

    /** Nothing landed, so nothing leaves the stack: the second press has the whole rangement still to do. */
    @Test
    fun aRunThatFailsImmediatelyChangesNothing() {
        val run: Run = Run(library, listOf(move("1", s1, s2)))

        run.apply(failingAtCall = 1)

        assertEquals(library, run.snapshot)
        assertEquals(2, run.plan.operations.size)
        assertEquals(SortWritePlan.ShelfStatus.Modified, run.plan.status(s1))
        assertEquals(SortWritePlan.ShelfStatus.Modified, run.plan.status(s2))
    }
}
