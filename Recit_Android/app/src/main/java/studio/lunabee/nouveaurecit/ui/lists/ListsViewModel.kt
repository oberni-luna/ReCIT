package studio.lunabee.nouveaurecit.ui.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.runningFold
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.ListRepository
import studio.lunabee.nouveaurecit.data.SessionCoordinator
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.ListWithElements

/**
 * `EntityListView`'s state: the lists from Room, filtered by the search text, each with the covers
 * of its first elements — read from Room too, and fetched once when the store lacks them.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class ListsViewModel(
    private val lists: ListRepository,
    private val entities: EntityRepository,
    private val session: SessionCoordinator,
    syncStatus: SyncStatus,
) : ViewModel() {
    private val all: StateFlow<List<ListWithElements>?> = lists.observeLists()
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    private val _query: MutableStateFlow<String> = MutableStateFlow("")
    val query: StateFlow<String> = _query.asStateFlow()

    /** `shouldShowPlaceholder(.lists)`: latched, so a pull-to-refresh never brings the placeholder back. */
    val hasSynced: StateFlow<Boolean> = syncStatus.domains
        .map { it[SyncStatus.Domain.Lists] in setOf(SyncStatus.State.Completed, SyncStatus.State.Failed) }
        .runningFold(false) { settled, now -> settled || now }
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val hasNoList: StateFlow<Boolean> = all.map { it.isNullOrEmpty() }
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

    private val images: Flow<Map<String, String?>> = all
        .map { ListsPresentation.coverUris(it.orEmpty()) }
        .distinctUntilChanged()
        .flatMapLatest { (workUris, authorUris) ->
            combine(
                entities.entities.observeWorksWithAuthors(workUris),
                entities.entities.observeAuthors(authorUris),
            ) { works, authors ->
                works.associate { it.work.uri to it.work.image } + authors.associate { it.uri to it.image }
            }
        }

    val rows: StateFlow<List<ListRowModel>> = combine(all, _query, images) { lists, query, images ->
        ListsPresentation.rows(lists.orEmpty(), query, images)
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    private val _isRefreshing: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

    private val requested: MutableSet<String> = mutableSetOf()

    init {
        viewModelScope.launch {
            all.collect { lists -> fetchMissingCovers(lists.orEmpty()) }
        }
    }

    fun setQuery(query: String) {
        _query.value = query
    }

    fun refresh() {
        if (_isRefreshing.value) return
        _isRefreshing.value = true
        viewModelScope.launch {
            try {
                session.refresh()
            } finally {
                _isRefreshing.value = false
            }
        }
    }

    /** Server-first. Returns whether it went through; [onError] says why not. */
    suspend fun deleteList(id: String, onError: (Throwable) -> Unit): Boolean = try {
        lists.deleteList(id)
        true
    } catch (error: Exception) {
        onError(error)
        false
    }

    /** `ListCoverFan.fetchMissing`, once per uri for the life of the screen. */
    private fun fetchMissingCovers(lists: List<ListWithElements>) {
        val (workUris, authorUris) = ListsPresentation.coverUris(lists)
        val works: List<String> = workUris.filter { requested.add(it) }
        val authors: List<String> = authorUris.filter { requested.add(it) }
        if (works.isNotEmpty()) viewModelScope.launch { runCatching { entities.getOrFetchWorks(works) } }
        if (authors.isNotEmpty()) viewModelScope.launch { runCatching { entities.getOrFetchAuthors(authors) } }
    }
}
