package studio.lunabee.nouveaurecit.ui.search

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.data.SearchResult

class SearchPhaseTest {
    @Test
    fun anEmptyFieldIsTheRestState() {
        assertEquals(SearchPhase.Recents, SearchPhase.current(query = "   ", submittedQuery = null))
    }

    @Test
    fun typedWithoutSendingSuggestsWhateverTheFocus() {
        assertEquals(SearchPhase.Suggesting("zola"), SearchPhase.current(query = "zola", submittedQuery = null))
    }

    @Test
    fun belowThresholdIsTyping() {
        assertEquals(SearchPhase.Typing("zo"), SearchPhase.current(query = " zo ", submittedQuery = null))
    }

    @Test
    fun threeCharactersSuggest() {
        assertEquals(SearchPhase.Suggesting("zol"), SearchPhase.current(query = "zol", submittedQuery = null))
    }

    @Test
    fun aSubmittedQueryShowsItsResults() {
        assertEquals(SearchPhase.Results("zola"), SearchPhase.current(query = "zola ", submittedQuery = "zola"))
    }

    @Test
    fun editingAfterSubmitLeavesResults() {
        assertEquals(SearchPhase.Suggesting("zolas"), SearchPhase.current(query = "zolas", submittedQuery = "zola"))
    }

    @Test
    fun emptyQueryNeverMatchesASubmission() {
        assertEquals(SearchPhase.Recents, SearchPhase.current(query = "", submittedQuery = ""))
    }

    @Test
    fun localQueryOnlyFromSuggestingOn() {
        assertNull(SearchPhase.Recents.localQuery)
        assertNull(SearchPhase.Typing("zo").localQuery)
        assertEquals("zol", SearchPhase.Suggesting("zol").localQuery)
        assertEquals("zola", SearchPhase.Results("zola").localQuery)
    }

    @Test
    fun suggestionsAreBooksPeopleEverythingFromThreeCharacters() {
        assertEquals(emptyList<SearchSuggestion>(), SearchSuggestion.suggestions("zo"))
        val suggestions: List<SearchSuggestion> = SearchSuggestion.suggestions("  zola ")
        assertEquals(SearchSuggestion.Kind.entries, suggestions.map { it.kind })
        assertEquals(listOf("zola", "zola", "zola"), suggestions.map { it.query })
        assertEquals(setOf(SearchResult.Type.Works), suggestions[0].types)
        assertEquals(setOf(SearchResult.Type.Humans), suggestions[1].types)
        assertEquals(setOf(SearchResult.Type.Humans, SearchResult.Type.Works), suggestions[2].types)
    }

    @Test
    fun keyboardSendsEverythingOnlyFromThreeCharacters() {
        assertNull(SearchSuggestion.everything("zo"))
        assertEquals(SearchSuggestion(SearchSuggestion.Kind.Everything, "zola"), SearchSuggestion.everything(" zola"))
    }

    @Test
    fun emphasisFindsTheQueryLooselyFromTheEnd() {
        assertEquals(17..21, SearchSuggestion.emphasisRange("emile", "Livres contenant Émile"))
        assertEquals(0..3, SearchSuggestion.emphasisRange("zola", "Zola"))
        assertNull(SearchSuggestion.emphasisRange("hugo", "Livres contenant Zola"))
    }

    @Test
    fun remoteStateSaysOneThingAtATime() {
        assertNull(RemoteSearchState.Idle.sign)
        assertEquals(RemoteSearchState.Sign.Loading, RemoteSearchState.Loading.sign)
        assertEquals(RemoteSearchState.Sign.NoResult, RemoteSearchState.Loaded(emptyList()).sign)
        assertEquals(RemoteSearchState.Sign.Failure, RemoteSearchState.Failed.sign)
        val result = SearchResult("1", SearchResult.Type.Works, "wd:Q1", "Germinal", null, null, 1.0)
        assertNull(RemoteSearchState.Loaded(listOf(result)).sign)
        assertEquals(listOf(result), RemoteSearchState.Loaded(listOf(result)).results)
        assertEquals(emptyList<SearchResult>(), RemoteSearchState.Failed.results)
    }
}
