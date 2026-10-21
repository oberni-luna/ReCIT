package studio.lunabee.nouveaurecit.ui.search

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

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
}
