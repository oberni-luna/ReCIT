package studio.lunabee.nouveaurecit.ui.search

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.SearchResult
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation

/**
 * `SearchTabView` + `SearchContent`'s state (features 0014, 0037): the field, its phase, the
 * recents, « Chez mes amis », and the call to inventaire.io.
 *
 * The field's own state (`query`, `submission`) is Compose state, so the text field never lags
 * behind a flow; everything read from the store is a `StateFlow`. Scoped to the tab's root entry,
 * so leaving the tab and coming back finds the query and its results as they were.
 */
class SearchViewModel(private val container: AppContainer) : ViewModel() {
    private val myUserId: StateFlow<String?> = container.users.myUserId

    val myUser: StateFlow<UserEntity?> = container.users.myUser.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    /** Every copy in the store — mine and my friends' — what the local matches rank. Newest first. */
    val allItems: StateFlow<List<ItemRow>> = container.inventory.observeAll()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    /** My friends' copies, most recently added first: « Chez mes amis » and its « Tout voir ». */
    val friendsItems: StateFlow<List<ItemRow>> = combine(allItems, myUserId) { items, id ->
        if (id == null) emptyList() else items.filter { it.item.ownerId != id }
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    /** `null` until the store answers, so the invitation does not flash in before my friends do. */
    val hasFriends: StateFlow<Boolean?> = container.users.observeByRelation(UserRelation.Friend)
        .map<List<UserEntity>, Boolean?> { it.isNotEmpty() }
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    /** This account's whole search history, most recent first. */
    private val history: StateFlow<List<String>> = myUserId
        .flatMapLatest { id -> id?.let { recentsFlow(it) } ?: flowOf(emptyList()) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val recents: StateFlow<List<String>> = history.map(RecentSearches::displayed)
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    var query: String by mutableStateOf("")
        private set

    var submission: SearchSuggestion? by mutableStateOf(null)
        private set

    private var attempt: Int by mutableIntStateOf(0)

    val phase: SearchPhase get() = SearchPhase.current(query = query, submittedQuery = submission?.query)

    private val _remoteState: MutableStateFlow<RemoteSearchState> = MutableStateFlow(RemoteSearchState.Idle)
    val remoteState: StateFlow<RemoteSearchState> = _remoteState.asStateFlow()

    private var answered: SearchAttempt? = null

    init {
        viewModelScope.launch {
            snapshotFlow { activeAttempt() }.distinctUntilChanged().collectLatest(::search)
        }
    }

    fun onQueryChange(value: String) {
        query = value
    }

    /** The keyboard's search key: the « everything » suggestion, from three characters on. */
    fun submitKeyboard() {
        SearchSuggestion.everything(query)?.let(::submit)
    }

    fun submit(suggestion: SearchSuggestion) {
        submission = suggestion
        val userId: String = myUserId.value ?: return
        viewModelScope.launch {
            val key: String = RecentSearches.preferenceKey(userId)
            val stored: List<String> = container.preferences.observeStrings(key).first()
            container.preferences.setStrings(key, RecentSearches.record(stored, suggestion.query))
        }
    }

    /** A tapped recent runs again as « everything ». */
    fun selectRecent(recent: String) {
        query = recent
        SearchSuggestion.everything(recent)?.let(::submit)
    }

    fun clearRecents() {
        val userId: String = myUserId.value ?: return
        viewModelScope.launch { container.preferences.setStrings(RecentSearches.preferenceKey(userId), emptyList()) }
    }

    /** « Réessayer », and the search list's pull-to-refresh. */
    fun retry() {
        attempt += 1
    }

    private fun recentsFlow(userId: String): Flow<List<String>> =
        container.preferences.observeStrings(RecentSearches.preferenceKey(userId))

    private fun activeAttempt(): SearchAttempt? {
        val current: SearchPhase = phase
        val sent: SearchSuggestion = submission ?: return null
        if (current !is SearchPhase.Results || sent.query != current.query) return null
        return SearchAttempt(sent, attempt)
    }

    /** One call per attempt, after a 250 ms debounce; a new attempt cancels the one in flight. */
    private suspend fun search(next: SearchAttempt?) {
        if (next == null) {
            _remoteState.value = RemoteSearchState.Idle
            answered = null
            return
        }
        if (answered == next) return
        _remoteState.value = RemoteSearchState.Loading
        delay(DEBOUNCE_MILLIS)
        try {
            val results: List<SearchResult> = container.search.search(next.submission.query, next.submission.types)
            _remoteState.value = RemoteSearchState.Loaded(results)
            answered = next
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            _remoteState.value = RemoteSearchState.Failed
            answered = next
            container.errorReporter.report(error)
        }
    }

    private data class SearchAttempt(val submission: SearchSuggestion, val count: Int)

    private companion object {
        const val DEBOUNCE_MILLIS: Long = 250
    }
}
