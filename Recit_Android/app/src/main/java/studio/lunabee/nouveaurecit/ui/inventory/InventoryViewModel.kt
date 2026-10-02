package studio.lunabee.nouveaurecit.ui.inventory

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
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity

/**
 * `ShelvesView` + `ShelvesContent` + `InventorySearchContent`'s state: my user, my shelves and
 * copies, the first-sync banner, and the unified search — its field, its phase, the recents and
 * the call to inventaire.io.
 *
 * The field's own state (`query`, `expanded`, `submission`) is Compose state, so the text field
 * never lags behind a flow; everything read from the store is a `StateFlow`.
 */
class InventoryViewModel(private val container: AppContainer) : ViewModel() {
    private val myUserId: StateFlow<String?> = container.users.myUserId

    val myUser: StateFlow<UserEntity?> = container.users.myUser.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    /** `null` until the store first answers, so the empty-shelf card never flashes on launch. */
    val shelves: StateFlow<List<ShelfWithItems>?> = myUserId
        .flatMapLatest { id -> id?.let(container.shelves::observeShelvesOf) ?: flowOf(null) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    /** My copies, newest first. */
    val myItems: StateFlow<List<ItemRow>?> = myUserId
        .flatMapLatest { id -> id?.let(container.inventory::observeItemsOf) ?: flowOf(null) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    /** Every copy in the store — mine and my friends' — what the local matches rank. */
    val allItems: StateFlow<List<ItemRow>> = container.inventory.observeAll()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val syncState: StateFlow<FirstSyncState> = combine(myUser, container.syncStatus.firstSyncProgress) { user, progress ->
        if (user == null) FirstSyncState.Synced else FirstSyncState.from(user.lastInventorySync, progress[user.id])
    }.stateIn(viewModelScope, SharingStarted.Eagerly, FirstSyncState.Synced)

    /** This account's whole search history, most recent first. */
    private val history: StateFlow<List<String>> = myUserId
        .flatMapLatest { id -> id?.let { recentsFlow(it) } ?: flowOf(emptyList()) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val recents: StateFlow<List<String>> = history.map(RecentSearches::displayed)
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    var query: String by mutableStateOf("")
        private set

    /** iOS's `isSearching`: the search surface is up (it stays up after a submit hides the keyboard). */
    var expanded: Boolean by mutableStateOf(false)
        private set

    var submission: SearchSuggestion? by mutableStateOf(null)
        private set

    private var attempt: Int by mutableIntStateOf(0)

    val phase: SearchPhase? get() = SearchPhase.current(isFocused = expanded, query = query, submittedQuery = submission?.query)

    private val _remoteState: MutableStateFlow<RemoteSearchState> = MutableStateFlow(RemoteSearchState.Idle)
    val remoteState: StateFlow<RemoteSearchState> = _remoteState.asStateFlow()

    private val _isRefreshing: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

    private var answered: SearchAttempt? = null

    init {
        viewModelScope.launch {
            snapshotFlow { activeAttempt() }.distinctUntilChanged().collectLatest(::search)
        }
    }

    fun onQueryChange(value: String) {
        query = value
    }

    fun onExpandedChange(value: Boolean) {
        expanded = value
        if (!value) {
            query = ""
            submission = null
        }
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

    /** The inventory's pull-to-refresh: the whole session sync, awaited. */
    fun refresh() {
        viewModelScope.launch {
            _isRefreshing.value = true
            try {
                container.session.refresh()
            } finally {
                _isRefreshing.value = false
            }
        }
    }

    private fun recentsFlow(userId: String): Flow<List<String>> =
        container.preferences.observeStrings(RecentSearches.preferenceKey(userId))

    private fun activeAttempt(): SearchAttempt? {
        val current: SearchPhase = phase ?: return null
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
