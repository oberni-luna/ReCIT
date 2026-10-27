package studio.lunabee.nouveaurecit.ui.editedition

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** What a picker's search shows: the query typed, the results found for it, and whether it was asked. */
data class SearchState<T>(
    val query: String = "",
    val results: List<T> = emptyList(),
    val hasSearched: Boolean = false,
) {
    val trimmedQuery: String get() = query.trim()
}

/**
 * The search as you type of the pickers (`.task(id: query)` on iOS): a beat after the last keystroke,
 * the previous search cancelled — cancelling is the debounce. Nothing under two letters is asked.
 *
 * A failed search is no dead end: it answers nothing, and the picker's « Créer » row is still there —
 * an error message would say nothing the empty list does not.
 */
class DebouncedSearch<T>(
    private val scope: CoroutineScope,
    private val search: suspend (query: String) -> List<T>,
) {
    private val _state: MutableStateFlow<SearchState<T>> = MutableStateFlow(SearchState())
    val state: StateFlow<SearchState<T>> = _state.asStateFlow()

    private var job: Job? = null

    fun setQuery(query: String) {
        _state.update { it.copy(query = query) }
        job?.cancel()
        val trimmed: String = query.trim()
        if (trimmed.length < MIN_QUERY_LENGTH) {
            _state.update { it.copy(results = emptyList(), hasSearched = false) }
            return
        }
        job = scope.launch {
            delay(DEBOUNCE_MILLIS)
            val results: List<T> = try {
                search(trimmed)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                emptyList()
            }
            _state.update { it.copy(results = results, hasSearched = true) }
        }
    }

    /** A page opening on a search starts it afresh, its field empty. */
    fun reset() {
        job?.cancel()
        _state.value = SearchState()
    }

    companion object {
        const val MIN_QUERY_LENGTH: Int = 2

        /** Long enough that typing does not fire a request per letter, short enough to follow the hand. */
        const val DEBOUNCE_MILLIS: Long = 300
    }
}
