package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.sorting.SortApplyLedger.Result
import studio.lunabee.nouveaurecit.data.sorting.SortApplyLedger.ShelfOutcome

/**
 * `SortApplyLedgerTests`: nothing is rolled back when a run stops partway, so the ledger's reduction *is*
 * the user's only account of what their library now contains. A tick against an étagère that was never
 * filled, or a "not created" naming one that was, is a lie about their data.
 *
 * The iOS suite's two re-run cases exercise the automatic proposal (`AutoSortPlan`), which is not ported.
 */
class SortApplyLedgerTest {
    private val names: List<String> = listOf("Imaginaire", "Policiers", "Essais")

    private fun ledger(names: List<String> = this.names): SortApplyLedger = SortApplyLedger(names.map { SortApplyLedger.Entry(it) })

    // Before the run

    @Test
    fun freshLedgerIsAllPending() {
        val progress: SortApplyLedger = ledger()

        assertEquals(names, progress.shelfNames)
        assertTrue(names.all { progress.outcome(it) == ShelfOutcome.Pending })
        assertEquals(Result.Running, progress.result)
        assertFalse(progress.isFinished)
        assertEquals(0, progress.landedCount)
    }

    @Test
    fun unknownShelfReadsAsPending() {
        assertEquals(ShelfOutcome.Pending, ledger().outcome("Bandes dessinées"))
    }

    @Test
    fun markingAnUnknownShelfIsIgnored() {
        val progress: SortApplyLedger = ledger().mark(ShelfOutcome.Landed, "Bandes dessinées")

        assertEquals(names, progress.shelfNames)
        assertTrue(progress.landedNames.isEmpty())
        assertEquals(ShelfOutcome.Pending, progress.outcome("Bandes dessinées"))
    }

    @Test
    fun duplicateNamesCollapse() {
        assertEquals(listOf("Imaginaire", "Policiers"), ledger(listOf("Imaginaire", "Policiers", "Imaginaire")).shelfNames)
    }

    /** Keyed apart from its name: two étagères sharing a name are two rows. */
    @Test
    fun twoEtageresSharingANameAreTwoRows() {
        val progress: SortApplyLedger = SortApplyLedger(
            listOf(SortApplyLedger.Entry("shelf:a", "Romans"), SortApplyLedger.Entry("shelf:b", "Romans")),
        ).mark(ShelfOutcome.Landed, "shelf:a")

        assertEquals(listOf("Romans", "Romans"), progress.shelfNames)
        assertEquals(ShelfOutcome.Landed, progress.outcome("shelf:a"))
        assertEquals(ShelfOutcome.Pending, progress.outcome("shelf:b"))
    }

    /** Immutable: marking returns a new ledger and leaves the one it was asked of alone. */
    @Test
    fun markingLeavesTheOriginalAlone() {
        val original: SortApplyLedger = ledger()
        original.mark(ShelfOutcome.Landed, "Imaginaire")

        assertEquals(ShelfOutcome.Pending, original.outcome("Imaginaire"))
    }

    // A run that finishes

    @Test
    fun partwayThroughIsStillRunning() {
        val progress: SortApplyLedger = ledger()
            .mark(ShelfOutcome.Landed, "Imaginaire")
            .mark(ShelfOutcome.Applying, "Policiers")

        assertEquals(Result.Running, progress.result)
        assertFalse(progress.isFinished)
        assertEquals(listOf("Imaginaire"), progress.landedNames)
    }

    @Test
    fun allLanded() {
        val progress: SortApplyLedger = names.fold(ledger()) { ledger, name -> ledger.mark(ShelfOutcome.Landed, name) }

        assertEquals(Result.AllLanded, progress.result)
        assertTrue(progress.isFinished)
        assertEquals(3, progress.landedCount)
        assertTrue(progress.notLandedNames.isEmpty())
    }

    @Test
    fun emptyLedgerIsFinished() {
        val progress: SortApplyLedger = SortApplyLedger(emptyList())

        assertEquals(Result.AllLanded, progress.result)
        assertTrue(progress.isFinished)
    }

    // A run that stops partway

    /** The report's whole job: landed, where it broke (which may exist empty), never attempted — in order. */
    @Test
    fun failurePartwaySplitsThreeWays() {
        val progress: SortApplyLedger = ledger()
            .mark(ShelfOutcome.Landed, "Imaginaire")
            .mark(ShelfOutcome.Failed, "Policiers")

        assertEquals(Result.Stopped(landed = listOf("Imaginaire"), failed = listOf("Policiers"), notAttempted = listOf("Essais")), progress.result)
        assertTrue(progress.isFinished)
        assertEquals(1, progress.landedCount)
        assertEquals(listOf("Policiers", "Essais"), progress.notLandedNames)
    }

    @Test
    fun failureOnTheFirstShelfReportsNothingCreated() {
        val progress: SortApplyLedger = ledger().mark(ShelfOutcome.Failed, "Imaginaire")

        assertEquals(Result.Stopped(landed = emptyList(), failed = listOf("Imaginaire"), notAttempted = listOf("Policiers", "Essais")), progress.result)
        assertEquals(0, progress.landedCount)
    }

    @Test
    fun failedShelfIsReportedApartFromTheUntouchedOnes() {
        val progress: SortApplyLedger = ledger()
            .mark(ShelfOutcome.Landed, "Imaginaire")
            .mark(ShelfOutcome.Failed, "Policiers")

        assertEquals(listOf("Policiers"), progress.failedNames)
        assertEquals(listOf("Essais"), progress.notAttemptedNames)
    }

    /** A shelf created but never filled is a failure, not a partial success. */
    @Test
    fun createdButUnfilledIsNotLanded() {
        val progress: SortApplyLedger = ledger()
            .mark(ShelfOutcome.Applying, "Imaginaire")
            .mark(ShelfOutcome.Failed, "Imaginaire")

        assertEquals(ShelfOutcome.Failed, progress.outcome("Imaginaire"))
        assertTrue(progress.landedNames.isEmpty())
    }
}
