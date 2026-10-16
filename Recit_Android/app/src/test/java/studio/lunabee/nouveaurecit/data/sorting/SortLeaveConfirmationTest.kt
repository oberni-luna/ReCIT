package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `SortLeaveConfirmationTests`: the close control asks before leaving unsaved changes behind, until the
 * user has once answered « Quitter ». What can go wrong is asking when there is nothing to say, or again.
 */
class SortLeaveConfirmationTest {
    @Test
    fun asksWhenChangesAreUnsaved() {
        assertTrue(SortLeaveConfirmation.isNeeded(hasPendingChanges = true, isApplying = false, isAcknowledged = false))
    }

    @Test
    fun leavesAtOnceWithNothingUnsaved() {
        assertFalse(SortLeaveConfirmation.isNeeded(hasPendingChanges = false, isApplying = false, isAcknowledged = false))
    }

    @Test
    fun neverAsksAgainOnceAcknowledged() {
        assertFalse(SortLeaveConfirmation.isNeeded(hasPendingChanges = true, isApplying = false, isAcknowledged = true))
    }

    /** A run in flight carries on without the screen: leaving then loses nothing. */
    @Test
    fun leavesAtOnceWhileARunIsWriting() {
        assertFalse(SortLeaveConfirmation.isNeeded(hasPendingChanges = true, isApplying = true, isAcknowledged = false))
    }
}
