package studio.lunabee.nouveaurecit.ui.inventory

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.model.Visibility

class RecentSearchesTest {
    @Test
    fun recordPutsTheSearchInFront() {
        assertEquals(listOf("hugo", "zola"), RecentSearches.record(listOf("zola"), "hugo"))
    }

    @Test
    fun recordNormalisesWhitespace() {
        assertEquals(listOf("monte cristo"), RecentSearches.record(emptyList(), "  monte   cristo "))
    }

    @Test
    fun blankQueryIsNotRecorded() {
        assertEquals(listOf("zola"), RecentSearches.record(listOf("zola"), "   "))
    }

    @Test
    fun foldedTwinMovesToFrontWithTheLatestSpelling() {
        val history: List<String> = listOf("hugo", "monte cristo", "zola")
        assertEquals(listOf("Monté Cristo", "hugo", "zola"), RecentSearches.record(history, "Monté Cristo"))
    }

    @Test
    fun threeAreDisplayedAndEverythingIsKept() {
        val history: List<String> = listOf("a1", "b2", "c3", "d4").fold(emptyList()) { acc, query -> RecentSearches.record(acc, query) }
        assertEquals(4, history.size)
        assertEquals(listOf("d4", "c3", "b2"), RecentSearches.displayed(history))
    }

    @Test
    fun historyIsPerUser() {
        assertNotEquals(RecentSearches.preferenceKey("me"), RecentSearches.preferenceKey("you"))
    }

    @Test
    fun firstSyncStateFollowsLastSyncThenProgress() {
        assertEquals(FirstSyncState.Synced, FirstSyncState.from(lastInventorySync = 1.0, progress = SyncStatus.Progress()))
        assertEquals(FirstSyncState.Waiting, FirstSyncState.from(lastInventorySync = null, progress = null))
        val running: FirstSyncState = FirstSyncState.from(null, SyncStatus.Progress(received = 1, announced = 4))
        assertEquals(0.25f, running.fraction)
        assertEquals(25, running.percent)
        assertEquals(null, FirstSyncState.from(null, SyncStatus.Progress()).percent)
    }

    @Test
    fun shelfVisibilityRoundTrips() {
        assertEquals(ShelfVisibility.Private, ShelfVisibility.from(emptyList()))
        assertEquals(ShelfVisibility.Friends, ShelfVisibility.from(listOf(Visibility.Friends)))
        assertEquals(ShelfVisibility.Public, ShelfVisibility.from(listOf(Visibility.Friends, Visibility.Public)))
        assertEquals(ShelfVisibility.Private, ShelfVisibility.from(listOf(Visibility.Groups)))
        ShelfVisibility.entries.forEach { assertEquals(it, ShelfVisibility.from(it.raw)) }
    }
}
