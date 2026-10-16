package studio.lunabee.nouveaurecit.data.scan

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `BatchScanStateMachineTests`: the batch scanner's rules, driven by events instead of a barcode in
 * front of a lens. The repeat-scan gate is why this suite exists — invisible until it breaks, at
 * which point the flow re-offers the book the user is still holding. Time is injected, so the
 * cooldown is asserted rather than slept through. The creation cases (feature 0020) are not ported.
 */
class BatchScanStateMachineTest {
    private var instant: Long = 0
    private val cooldown: Long = 2_000
    private val firstCode: String = "9782367935836"
    private val secondCode: String = "9780007532766"

    private fun makeMachine(): BatchScanStateMachine = BatchScanStateMachine(cooldownMillis = cooldown, now = { instant })

    private fun advance(millis: Long) {
        instant += millis
    }

    private fun book(code: String): ScannedBook = ScannedBook(
        uri = "inv:$code",
        title = "Le Nom du vent",
        authors = listOf("Patrick Rothfuss"),
        coverImageUrl = null,
        code = code,
    )

    /** Scan, resolve, file, confirm, clear — so the gate tests start from a book genuinely handled. */
    private fun fileOneBook(code: String, machine: BatchScanStateMachine) {
        machine.apply(BatchScanEvent.CodeSeen(code))
        machine.apply(BatchScanEvent.LookupResolved(book(code)))
        machine.apply(BatchScanEvent.AddStarted)
        machine.apply(BatchScanEvent.AddFinished)
        machine.apply(BatchScanEvent.Cleared)
    }

    @Test
    fun aScanRunsFromTheBarcodeToAFiledBookAndGivesTheScreenBack() {
        val machine: BatchScanStateMachine = makeMachine()
        val scanned: ScannedBook = book(firstCode)
        assertEquals(BatchScanState.Idle, machine.state)

        assertTrue(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        assertEquals(BatchScanState.LookingUp(firstCode), machine.state)
        assertTrue(machine.apply(BatchScanEvent.LookupResolved(scanned)))
        assertEquals(BatchScanState.Resolved(scanned), machine.state)
        assertTrue(machine.apply(BatchScanEvent.AddStarted))
        assertEquals(BatchScanState.Adding(scanned), machine.state)
        assertTrue(machine.apply(BatchScanEvent.AddFinished))
        assertEquals(BatchScanState.Added(scanned), machine.state)
        assertTrue(machine.apply(BatchScanEvent.Cleared))
        assertEquals(BatchScanState.Idle, machine.state)
    }

    @Test
    fun theResolvedStateCarriesTheBookTheRowDraws() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        assertEquals(book(firstCode), machine.state.book)
        assertTrue(machine.state.showsRow)
    }

    @Test
    fun aSecondCodeIsIgnoredWhileALookupRunsAndWhileAnAddIsInFlight() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        assertEquals(BatchScanState.LookingUp(firstCode), machine.state)

        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        machine.apply(BatchScanEvent.AddStarted)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        assertEquals(BatchScanState.Adding(book(firstCode)), machine.state)
    }

    @Test
    fun aLookupLandingForACodeTheRowNoLongerWaitsForIsDropped() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.Cleared)
        assertFalse(machine.apply(BatchScanEvent.LookupResolved(book(firstCode))))
        assertEquals(BatchScanState.Idle, machine.state)
    }

    @Test
    fun theBookStillInFrontOfTheCameraAfterBeingAddedIsNotOfferedAgain() {
        val machine: BatchScanStateMachine = makeMachine()
        fileOneBook(firstCode, machine)
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        assertEquals(BatchScanState.Idle, machine.state)
    }

    @Test
    fun aBookHeldInFrameStaysGatedHoweverLongItIsHeld() {
        val machine: BatchScanStateMachine = makeMachine()
        fileOneBook(firstCode, machine)
        repeat(20) {
            advance(cooldown / 2)
            assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        }
        assertEquals(BatchScanState.Idle, machine.state)
    }

    @Test
    fun sightingsDuringAPendingRowKeepTheGateClosedAfterItClears() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        repeat(10) {
            advance(cooldown / 2)
            assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        }
        machine.apply(BatchScanEvent.AddStarted)
        machine.apply(BatchScanEvent.AddFinished)
        machine.apply(BatchScanEvent.Cleared)
        advance(cooldown / 2)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
    }

    @Test
    fun aDifferentBookIsRecognisedImmediately() {
        val machine: BatchScanStateMachine = makeMachine()
        fileOneBook(firstCode, machine)
        advance(200)
        assertTrue(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        assertEquals(BatchScanState.LookingUp(secondCode), machine.state)
    }

    @Test
    fun theGateRemembersOneCodeSoTheNextBookReleasesThePreviousOne() {
        val machine: BatchScanStateMachine = makeMachine()
        fileOneBook(firstCode, machine)
        advance(200)
        fileOneBook(secondCode, machine)
        advance(200)
        assertTrue(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
    }

    @Test
    fun aBookTakenOutOfFrameForTheCooldownMayBeScannedAgain() {
        val machine: BatchScanStateMachine = makeMachine()
        fileOneBook(firstCode, machine)
        advance(cooldown - 500)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        // The sighting above pushed the deadline back, so the full cooldown has to pass from it.
        advance(cooldown + 500)
        assertTrue(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        assertEquals(BatchScanState.LookingUp(firstCode), machine.state)
    }

    @Test
    fun anUnresolvableCodeSaysSoAndStaysGated() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        assertTrue(machine.apply(BatchScanEvent.LookupFailed(firstCode)))
        assertEquals(BatchScanState.NotFound(firstCode), machine.state)
        assertTrue(machine.state.showsRow)
        machine.apply(BatchScanEvent.Cleared)
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
    }

    @Test
    fun aBookAlreadyInTheInventoryStaysGatedToo() {
        val machine: BatchScanStateMachine = makeMachine()
        val scanned: ScannedBook = book(firstCode)
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        assertTrue(machine.apply(BatchScanEvent.LookupResolvedAlreadyOwned(scanned)))
        assertEquals(BatchScanState.AlreadyOwned(scanned), machine.state)
        assertEquals(scanned, machine.state.book)
        machine.apply(BatchScanEvent.Cleared)
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
    }

    @Test
    fun aLookupPastItsDeadlineLandsInTheUnknownEditionState() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        assertTrue(machine.apply(BatchScanEvent.LookupTimedOut(firstCode)))
        assertEquals(BatchScanState.NotFound(firstCode), machine.state)
    }

    @Test
    fun aTimedOutCodeIsNotReofferedWhileTheBookIsStillInFrame() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupTimedOut(firstCode))
        machine.apply(BatchScanEvent.Cleared)
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
    }

    @Test
    fun aLookupLandingAfterItsOwnTimeoutIsDropped() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupTimedOut(firstCode))
        assertFalse(machine.apply(BatchScanEvent.LookupResolved(book(firstCode))))
        assertEquals(BatchScanState.NotFound(firstCode), machine.state)
    }

    @Test
    fun aBookAlreadyInTheInventoryStillHoldsTheScreenAgainstTheNextBook() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolvedAlreadyOwned(book(firstCode)))
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        machine.apply(BatchScanEvent.Cleared)
        assertTrue(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        assertEquals(BatchScanState.LookingUp(secondCode), machine.state)
    }

    @Test
    fun aimingAtADifferentBookReplacesAnUnknownEdition() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupFailed(firstCode))
        advance(400)
        assertTrue(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        assertEquals(BatchScanState.LookingUp(secondCode), machine.state)
    }

    @Test
    fun theSameUnknownBookStillInFrameDoesNotRestartALookup() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupFailed(firstCode))
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        assertEquals(BatchScanState.NotFound(firstCode), machine.state)
    }

    @Test
    fun aimingAtADifferentBookReplacesABookWaitingToBeFiled() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        advance(400)
        assertTrue(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        assertEquals(BatchScanState.LookingUp(secondCode), machine.state)
    }

    @Test
    fun theSameBookStillInFrameDoesNotRestartItsOwnLookup() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(firstCode)))
        assertEquals(BatchScanState.Resolved(book(firstCode)), machine.state)
    }

    @Test
    fun aBookBeingFiledIsNotReplacedByAnotherBarcode() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        machine.apply(BatchScanEvent.AddStarted)
        advance(400)
        assertFalse(machine.apply(BatchScanEvent.CodeSeen(secondCode)))
        assertEquals(BatchScanState.Adding(book(firstCode)), machine.state)
    }

    @Test
    fun aFailedAddLeavesTheBookOnScreenAndTheActionRetryable() {
        val machine: BatchScanStateMachine = makeMachine()
        val scanned: ScannedBook = book(firstCode)
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(scanned))
        machine.apply(BatchScanEvent.AddStarted)
        assertTrue(machine.apply(BatchScanEvent.AddFailed))
        assertEquals(BatchScanState.Resolved(scanned), machine.state)
        assertTrue(machine.apply(BatchScanEvent.AddStarted))
        assertTrue(machine.apply(BatchScanEvent.AddFinished))
        assertEquals(BatchScanState.Added(scanned), machine.state)
    }

    @Test
    fun aSessionThatHasFiledNothingCountsNothing() {
        val machine: BatchScanStateMachine = makeMachine()
        assertEquals(0, machine.addedBookCount)
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        assertEquals(0, machine.addedBookCount)
    }

    @Test
    fun eachFiledBookCountsOnceAndTheTallySurvivesTheRowClearing() {
        val machine: BatchScanStateMachine = makeMachine()
        fileOneBook(firstCode, machine)
        assertEquals(1, machine.addedBookCount)
        advance(200)
        machine.apply(BatchScanEvent.CodeSeen(secondCode))
        assertEquals(1, machine.addedBookCount)
        machine.apply(BatchScanEvent.LookupResolved(book(secondCode)))
        machine.apply(BatchScanEvent.AddStarted)
        machine.apply(BatchScanEvent.AddFinished)
        assertEquals(2, machine.addedBookCount)
        machine.apply(BatchScanEvent.Cleared)
        assertEquals(2, machine.addedBookCount)
    }

    @Test
    fun aFailedAddDoesNotCountAndTheRetryThatLandsDoes() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupResolved(book(firstCode)))
        machine.apply(BatchScanEvent.AddStarted)
        machine.apply(BatchScanEvent.AddFailed)
        assertEquals(0, machine.addedBookCount)
        machine.apply(BatchScanEvent.AddStarted)
        machine.apply(BatchScanEvent.AddFinished)
        assertEquals(1, machine.addedBookCount)
    }

    @Test
    fun anOutcomeTheUserCannotActOnDoesNotCount() {
        val machine: BatchScanStateMachine = makeMachine()
        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        machine.apply(BatchScanEvent.LookupFailed(firstCode))
        machine.apply(BatchScanEvent.Cleared)
        advance(cooldown + 1_000)
        machine.apply(BatchScanEvent.CodeSeen(secondCode))
        machine.apply(BatchScanEvent.LookupResolvedAlreadyOwned(book(secondCode)))
        machine.apply(BatchScanEvent.Cleared)
        assertEquals(0, machine.addedBookCount)
    }

    @Test
    fun aBarcodeTheRepeatGateRefusesDoesNotCount() {
        val machine: BatchScanStateMachine = makeMachine()
        fileOneBook(firstCode, machine)
        repeat(10) {
            advance(cooldown / 2)
            machine.apply(BatchScanEvent.CodeSeen(firstCode))
            machine.apply(BatchScanEvent.AddStarted)
            machine.apply(BatchScanEvent.AddFinished)
        }
        assertEquals(1, machine.addedBookCount)
    }

    @Test
    fun outcomesThatDoNotMatchTheCurrentStateAreIgnored() {
        val machine: BatchScanStateMachine = makeMachine()
        assertFalse(machine.apply(BatchScanEvent.AddStarted))
        assertFalse(machine.apply(BatchScanEvent.AddFinished))
        assertFalse(machine.apply(BatchScanEvent.AddFailed))
        assertFalse(machine.apply(BatchScanEvent.Cleared))
        assertFalse(machine.apply(BatchScanEvent.LookupTimedOut(firstCode)))
        assertEquals(BatchScanState.Idle, machine.state)

        machine.apply(BatchScanEvent.CodeSeen(firstCode))
        assertFalse(machine.apply(BatchScanEvent.AddStarted))
        assertFalse(machine.apply(BatchScanEvent.AddFinished))
        assertFalse(machine.apply(BatchScanEvent.LookupResolvedAlreadyOwned(book(secondCode))))
        assertEquals(BatchScanState.LookingUp(firstCode), machine.state)
        assertEquals(0, machine.addedBookCount)
    }
}
