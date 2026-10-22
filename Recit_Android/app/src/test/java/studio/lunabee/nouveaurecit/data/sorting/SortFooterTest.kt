package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** `SortFooter`'s order: a settled run's account, the recap, then the two idle readings. */
class SortFooterTest {
    private val library: SortSnapshot = SortSnapshot(
        shelves = listOf(SortSnapshot.Shelf("s1", "Poésie", emptyList())),
        books = listOf(SortBook(id = "1", title = "Alcools")),
    )
    private val filing: List<SortChange> = listOf(SortChange.MoveBook("1", SortSectionId.Unshelved, SortSectionId.Shelf("s1")))
    private val landed: SortApplyLedger = SortApplyLedger(listOf(SortApplyLedger.Entry("shelf:s1", "Poésie")))
        .mark(SortApplyLedger.ShelfOutcome.Landed, "shelf:s1")
    private val stopped: SortApplyLedger = SortApplyLedger(listOf(SortApplyLedger.Entry("shelf:s1", "Poésie")))
        .mark(SortApplyLedger.ShelfOutcome.Failed, "shelf:s1")

    @Test
    fun nothingPendingReadsIdleOrAsksForADragWithoutShelves() {
        assertEquals(SortFooter.Idle, SortFooter.of(SortWritePlan(library), progress = null, hasShelves = true))
        assertEquals(SortFooter.IdleWithoutShelves, SortFooter.of(SortWritePlan(library), progress = null, hasShelves = false))
    }

    @Test
    fun pendingChangesReadAsTheRecap() {
        assertTrue(SortFooter.of(SortWritePlan(library, filing), progress = null, hasShelves = true) is SortFooter.Recap)
    }

    @Test
    fun aSettledRunIsReportedUntilTheNextChange() {
        assertEquals(SortFooter.Report(landed), SortFooter.of(SortWritePlan(library), landed, hasShelves = true))
        // Android departs from iOS here: the report of a whole run no longer hides the next recap.
        assertTrue(SortFooter.of(SortWritePlan(library, filing), landed, hasShelves = true) is SortFooter.Recap)
    }

    @Test
    fun aStoppedRunStaysReportedWhileItsRestIsPending() {
        assertEquals(SortFooter.Report(stopped), SortFooter.of(SortWritePlan(library, filing), stopped, hasShelves = true))
    }
}
