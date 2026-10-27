package studio.lunabee.nouveaurecit.ui.editedition

import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** The pickers' search as you type: a beat after the last keystroke, only the last query, never an error. */
class DebouncedSearchTest {
    @Test
    fun onlyTheLastQueryIsAskedOnceTypingPauses() = runTest {
        val asked: MutableList<String> = mutableListOf()
        val search = DebouncedSearch(backgroundScope) { query -> asked += query; listOf("$query!") }

        search.setQuery("Le")
        advanceTimeBy(DebouncedSearch.DEBOUNCE_MILLIS / 2)
        search.setQuery("Le Guin ")
        advanceTimeBy(DebouncedSearch.DEBOUNCE_MILLIS + 1)
        runCurrent()

        assertEquals(listOf("Le Guin"), asked)
        assertEquals(listOf("Le Guin!"), search.state.value.results)
        assertTrue(search.state.value.hasSearched)
    }

    @Test
    fun aSingleLetterAsksNothingAndClearsTheResults() = runTest {
        val search = DebouncedSearch(backgroundScope) { listOf(it) }
        search.setQuery("Dune")
        advanceTimeBy(DebouncedSearch.DEBOUNCE_MILLIS + 1)
        runCurrent()
        search.setQuery("D")

        assertTrue(search.state.value.results.isEmpty())
        assertFalse(search.state.value.hasSearched)
        assertEquals("D", search.state.value.query)
    }

    @Test
    fun aFailedSearchAnswersNothing() = runTest {
        val search: DebouncedSearch<String> = DebouncedSearch(backgroundScope) { error("offline") }
        search.setQuery("Dune")
        advanceTimeBy(DebouncedSearch.DEBOUNCE_MILLIS + 1)
        runCurrent()

        assertTrue(search.state.value.results.isEmpty())
        assertTrue(search.state.value.hasSearched)
    }

    @Test
    fun resetEmptiesTheField() = runTest {
        val search = DebouncedSearch(backgroundScope) { listOf(it) }
        search.setQuery("Dune")
        search.reset()
        advanceTimeBy(DebouncedSearch.DEBOUNCE_MILLIS + 1)
        runCurrent()

        assertEquals(SearchState<String>(), search.state.value)
    }
}
