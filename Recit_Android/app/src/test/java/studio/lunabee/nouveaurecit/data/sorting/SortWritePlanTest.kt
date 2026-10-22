package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.sorting.SortWritePlan.ShelfStatus
import studio.lunabee.nouveaurecit.data.sorting.SortWritePlan.Summary.Clause

/**
 * `SortWritePlanTests`: what applying would do, and what the screen says it would do — asserted as one
 * thing, because they are one reduction. A pill marking an étagère « Modifiée » while the write leaves it
 * alone is the screen lying to a user about their own library.
 */
class SortWritePlanTest {
    private val s1: SortSectionId = SortSectionId.Shelf("s1")
    private val s2: SortSectionId = SortSectionId.Shelf("s2")
    private val s3: SortSectionId = SortSectionId.Shelf("s3")
    private val pile: SortSectionId = SortSectionId.Unshelved

    private fun book(id: String): SortBook = SortBook(id = id, title = "Livre $id")

    /** Two étagères with books on them, one empty étagère, and two books on none. */
    private val library: SortSnapshot = SortSnapshot(
        shelves = listOf(
            SortSnapshot.Shelf("s1", "Romans classiques", listOf("1", "2")),
            SortSnapshot.Shelf("s2", "Poésie", listOf("3")),
            SortSnapshot.Shelf("s3", "Bandes dessinées", emptyList()),
        ),
        books = listOf(book("1"), book("2"), book("3"), book("4"), book("5")),
    )

    private fun operation(plan: SortWritePlan, section: SortSectionId): SortWritePlan.ShelfWrite? =
        plan.operations.firstOrNull { it.section == section }

    private fun move(bookId: String, from: SortSectionId, to: SortSectionId): SortChange = SortChange.MoveBook(bookId, from, to)

    // Nothing done, and work that undoes itself

    @Test
    fun anEmptyStackWritesNothingAndRecapsNothing() {
        val plan: SortWritePlan = SortWritePlan(library)

        assertFalse(plan.hasPendingChanges)
        assertFalse(plan.hasWork)
        assertTrue(plan.operations.isEmpty())
        assertEquals(ShelfStatus.Untouched, plan.status(s1))
        assertEquals(ShelfStatus.Untouched, plan.status(s2))
        assertEquals(ShelfStatus.Untouched, plan.status(s3))
        assertEquals(SortWritePlan.Summary(shelvesToCreate = 0, shelvesModified = 0, booksFiled = 0, booksLeftUnshelved = 2), plan.summary)
    }

    /** Out of an étagère and back: a stack is left — the buttons still offer to save — but nothing to write. */
    @Test
    fun aBookDraggedOutOfAnEtagereAndBackLeavesNothingToWriteAndNoPill() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("1", s1, pile), move("1", pile, s1)))

        assertTrue(plan.hasPendingChanges)
        assertFalse(plan.hasWork)
        assertTrue(plan.operations.isEmpty())
        assertEquals(ShelfStatus.Untouched, plan.status(s1))
        assertEquals(0, plan.summary.booksFiled)
        assertEquals(2, plan.summary.booksLeftUnshelved)
    }

    @Test
    fun aBookThatTravelsAndComesHomeWritesNothing() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("3", s2, s1), move("3", s1, pile), move("3", pile, s2)))

        assertTrue(plan.operations.isEmpty())
        assertEquals(ShelfStatus.Untouched, plan.status(s1))
        assertEquals(ShelfStatus.Untouched, plan.status(s2))
    }

    // What reaches the endpoints

    @Test
    fun aBookMovedAcrossThreeSectionsIsOneRemovalAndOneAddition() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("1", s1, s2), move("1", s2, pile), move("1", pile, s3)))

        assertEquals(2, plan.operations.size)
        assertEquals(listOf("1"), operation(plan, s1)?.removals)
        assertEquals(emptyList<String>(), operation(plan, s1)?.additions)
        assertEquals(listOf("1"), operation(plan, s3)?.additions)
        assertEquals(emptyList<String>(), operation(plan, s3)?.removals)
        assertNull(operation(plan, s2))
        assertEquals(ShelfStatus.Untouched, plan.status(s2))
        assertEquals(1, plan.summary.booksFiled)
    }

    @Test
    fun aMoveFromOneEtagereToAnotherRemovesOnceAndAddsOnce() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("2", s1, s2)))

        assertEquals(2, plan.operations.size)
        assertEquals(listOf("2"), operation(plan, s1)?.removals)
        assertEquals(emptyList<String>(), operation(plan, s1)?.additions)
        assertEquals(listOf("2"), operation(plan, s2)?.additions)
        assertEquals(emptyList<String>(), operation(plan, s2)?.removals)
        assertEquals(ShelfStatus.Modified, plan.status(s1))
        assertEquals(ShelfStatus.Modified, plan.status(s2))
        assertEquals(2, plan.summary.shelvesModified)
        assertEquals(0, plan.summary.shelvesToCreate)
    }

    @Test
    fun aBookDroppedIntoThePileIsARemovalAndNothingElse() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("3", s2, pile)))

        assertEquals(1, plan.operations.size)
        assertEquals(listOf("3"), operation(plan, s2)?.removals)
        assertEquals(emptyList<String>(), operation(plan, s2)?.additions)
        assertEquals(false, operation(plan, s2)?.createsShelf)
        assertEquals(0, plan.summary.booksFiled)
        assertEquals(3, plan.summary.booksLeftUnshelved)
    }

    /** Every group takes books off before it puts books on. */
    @Test
    fun anEtagereTakesBooksOffBeforeItPutsBooksOn() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("1", s1, pile), move("4", pile, s1)))
        val write: SortWritePlan.ShelfWrite? = operation(plan, s1)

        assertEquals(listOf("1"), write?.removals)
        assertEquals(listOf("4"), write?.additions)
    }

    // Étagères that appear, and étagères that empty

    @Test
    fun aDraftHoldingBooksIsOneCreationCarryingItsMembers() {
        val draftId: String = SortDraftId.make()
        val draft: SortSectionId = SortSectionId.Draft(draftId)
        val plan: SortWritePlan = SortWritePlan(
            library,
            listOf(SortChange.CreateShelf(draftId, "Science-fiction"), move("4", pile, draft), move("5", pile, draft)),
        )
        val write: SortWritePlan.ShelfWrite? = operation(plan, draft)

        assertEquals(true, write?.createsShelf)
        assertEquals("Science-fiction", write?.name)
        assertEquals(listOf("4", "5"), write?.additions)
        assertEquals(emptyList<String>(), write?.removals)
        assertEquals(ShelfStatus.New, plan.status(draft))
        assertEquals(1, plan.summary.shelvesToCreate)
        assertEquals(2, plan.summary.booksFiled)
        assertEquals(0, plan.summary.booksLeftUnshelved)
    }

    /** A new étagère left empty is created all the same: naming a shelf is the instruction. */
    @Test
    fun aDraftLeftEmptyIsCreatedAllTheSame() {
        val draftId: String = SortDraftId.make()
        val plan: SortWritePlan = SortWritePlan(library, listOf(SortChange.CreateShelf(draftId, "Science-fiction")))
        val write: SortWritePlan.ShelfWrite? = plan.operations.firstOrNull()

        assertEquals(1, plan.operations.size)
        assertTrue(plan.hasWork)
        assertTrue(plan.hasPendingChanges)
        assertEquals(true, write?.createsShelf)
        assertEquals("Science-fiction", write?.name)
        assertEquals(emptyList<String>(), write?.additions)
        assertEquals(emptyList<String>(), write?.removals)
        assertEquals(ShelfStatus.New, plan.status(SortSectionId.Draft(draftId)))
        assertEquals(1, plan.summary.shelvesToCreate)
        assertEquals(0, plan.summary.booksFiled)
    }

    /** Filling a draft and emptying it again leaves the étagère to be created and the book where it started. */
    @Test
    fun aDraftFilledAndThenEmptiedIsStillCreated() {
        val draftId: String = SortDraftId.make()
        val draft: SortSectionId = SortSectionId.Draft(draftId)
        val plan: SortWritePlan = SortWritePlan(
            library,
            listOf(SortChange.CreateShelf(draftId, "Science-fiction"), move("4", pile, draft), move("4", draft, pile)),
        )

        assertEquals(1, plan.operations.size)
        assertEquals(true, plan.operations.first().createsShelf)
        assertTrue(plan.operations.first().additions.isEmpty())
        assertEquals(1, plan.summary.shelvesToCreate)
        assertEquals(2, plan.summary.booksLeftUnshelved)
    }

    /** An étagère emptied by dragging keeps its place and is marked as changed — never deleted. */
    @Test
    fun anEtagereEmptiedByDraggingIsModifiedAndNeverDeleted() {
        val changes: List<SortChange> = listOf(move("3", s2, s1))
        val plan: SortWritePlan = SortWritePlan(library, changes)

        assertEquals(ShelfStatus.Modified, plan.status(s2))
        assertEquals(listOf("3"), operation(plan, s2)?.removals)
        assertEquals(false, operation(plan, s2)?.createsShelf)

        val projection: SortProjection = SortProjection(library, changes)
        assertTrue(projection.sections.any { it.id == s2 && it.books.isEmpty() })
    }

    @Test
    fun anUntouchedEtagereIsLeftAlone() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("4", pile, s3)))

        assertEquals(ShelfStatus.Untouched, plan.status(s1))
        assertEquals(ShelfStatus.Untouched, plan.status(s2))
        assertNull(operation(plan, s1))
        assertNull(operation(plan, s2))
        assertEquals(ShelfStatus.Modified, plan.status(s3))
    }

    // Which clauses the sentence is worth saying

    /** A count of zero is not a clause. */
    @Test
    fun aCountOfZeroIsNotSaidAtAll() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("4", pile, s1)))

        assertEquals(0, plan.summary.shelvesToCreate)
        assertEquals(listOf(Clause.ShelvesModified(1), Clause.BooksFiled(1), Clause.BooksLeftUnshelved(1)), plan.summary.clauses)
    }

    @Test
    fun everyClauseIsSaidInOrderWhenEveryCountMoves() {
        val draftId: String = SortDraftId.make()
        val plan: SortWritePlan = SortWritePlan(
            library,
            listOf(SortChange.CreateShelf(draftId, "Science-fiction"), move("4", pile, SortSectionId.Draft(draftId)), move("1", s1, s2)),
        )

        assertEquals(
            listOf(Clause.ShelvesToCreate(1), Clause.ShelvesModified(2), Clause.BooksFiled(2), Clause.BooksLeftUnshelved(1)),
            plan.summary.clauses,
        )
    }

    /** A stack that coalesces to nothing has no work, but the unshelved clause survives: the recap gates on hasWork. */
    @Test
    fun aStackThatCoalescesToNothingStillLeavesTheUnshelvedClause() {
        val plan: SortWritePlan = SortWritePlan(library, listOf(move("1", s1, s2), move("1", s2, s1)))

        assertTrue(plan.hasPendingChanges)
        assertFalse(plan.hasWork)
        assertEquals(listOf(Clause.BooksLeftUnshelved(2)), plan.summary.clauses)
    }

    // The pills, the recap and the write, on the same fixtures

    /** All three readings come out of one reduction, so on any session they say the same thing. */
    @Test
    fun thePillsTheRecapAndTheOperationsAlwaysAgree() {
        for ((name, changes) in fixtures()) {
            val plan: SortWritePlan = SortWritePlan(library, changes)
            val projection: SortProjection = SortProjection(library, changes)

            var newPills: Int = 0
            var modifiedPills: Int = 0
            for (section in projection.sections) {
                val write: SortWritePlan.ShelfWrite? = operation(plan, section.id)
                when (plan.status(section.id)) {
                    ShelfStatus.Untouched -> assertNull(name, write)
                    ShelfStatus.New -> {
                        newPills += 1
                        assertEquals(name, true, write?.createsShelf)
                        assertEquals(name, emptyList<String>(), write?.removals)
                    }
                    ShelfStatus.Modified -> {
                        modifiedPills += 1
                        assertNotNull(name, write)
                        assertEquals(name, false, write?.createsShelf)
                        assertTrue(name, write!!.removals.isNotEmpty() || write.additions.isNotEmpty())
                    }
                }
            }

            // The recap's numbers are the pills, counted — and the operations, counted.
            assertEquals(name, newPills, plan.summary.shelvesToCreate)
            assertEquals(name, modifiedPills, plan.summary.shelvesModified)
            assertEquals(name, plan.operations.count { it.createsShelf }, plan.summary.shelvesToCreate)
            assertEquals(name, plan.operations.sumOf { it.additions.size }, plan.summary.booksFiled)
            assertEquals(name, plan.operations.isNotEmpty(), plan.hasWork)
            // And the last number is what the screen shows in « À ranger ».
            assertEquals(name, projection.unshelved.books.size, plan.summary.booksLeftUnshelved)
            // As many clauses as non-zero counts: none dropped, none padded with a zero.
            val counts: List<Int> = with(plan.summary) { listOf(shelvesToCreate, shelvesModified, booksFiled, booksLeftUnshelved) }
            assertEquals(name, counts.count { it > 0 }, plan.summary.clauses.size)
        }
    }

    /** One sorting session per entry, named so a failure says which session broke. */
    private fun fixtures(): List<Pair<String, List<SortChange>>> {
        val draftId: String = SortDraftId.make()
        val otherDraftId: String = SortDraftId.make()
        val draft: SortSectionId = SortSectionId.Draft(draftId)
        return listOf(
            "nothing done" to emptyList(),
            "one book filed" to listOf(move("4", pile, s1)),
            "one book unfiled" to listOf(move("1", s1, pile)),
            "an étagère emptied" to listOf(move("3", s2, pile)),
            "out and back" to listOf(move("1", s1, s2), move("1", s2, s1)),
            "a book across three sections" to listOf(move("2", s1, s2), move("2", s2, pile), move("2", pile, s3)),
            "a draft filled" to listOf(SortChange.CreateShelf(draftId, "Science-fiction"), move("4", pile, draft), move("5", pile, draft)),
            "a draft left empty" to listOf(SortChange.CreateShelf(draftId, "Science-fiction")),
            "one draft filled, one left empty" to listOf(
                SortChange.CreateShelf(draftId, "Science-fiction"),
                SortChange.CreateShelf(otherDraftId, "Essais"),
                move("4", pile, draft),
            ),
            "a whole afternoon of sorting" to listOf(
                SortChange.CreateShelf(draftId, "Science-fiction"),
                move("1", s1, draft),
                move("2", s1, pile),
                move("3", s2, s3),
                move("4", pile, s2),
                move("5", pile, draft),
                move("5", draft, pile),
                SortChange.CreateShelf(otherDraftId, "Essais"),
            ),
        )
    }
}
