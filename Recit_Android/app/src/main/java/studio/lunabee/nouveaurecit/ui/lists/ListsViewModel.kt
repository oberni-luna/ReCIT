package studio.lunabee.nouveaurecit.ui.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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
 * `EntityListView`'s state: my lists from Room, filtered by the search text, each with the covers
 * of its first elements ([ListRowFeed]).
 */
class ListsViewModel(
    private val lists: ListRepository,
    private val entities: EntityRepository,
    private val session: SessionCoordinator,
    syncStatus: SyncStatus,
) : ViewModel() {
    private val all: StateFlow<List<ListWithElements>?> = lists.observeMyLists()
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

    val rows: StateFlow<List<ListRowModel>> = ListRowFeed(entities, viewModelScope)
        .rows(all.map { it.orEmpty() }, _query)
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    private val _isRefreshing: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

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
}
