package studio.lunabee.nouveaurecit.ui.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.runningFold
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.ListRepository
import studio.lunabee.nouveaurecit.data.SessionCoordinator
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.UserRepository
import studio.lunabee.nouveaurecit.data.model.UserRelation

/**
 * `EntityListView`'s state: every list Room holds, split into mine and my friends' ([ListsTabSections]),
 * filtered by the search text, each with the covers of its first elements ([ListRowFeed]).
 */
class ListsViewModel(
    private val lists: ListRepository,
    users: UserRepository,
    entities: EntityRepository,
    private val session: SessionCoordinator,
    syncStatus: SyncStatus,
) : ViewModel() {
    /** The rows of « Mes listes » and of « Dans mon réseau », as the search leaves them. */
    data class Rows(
        val mine: List<ListRowModel> = emptyList(),
        val network: List<ListRowModel> = emptyList(),
    )

    /** Everything there is to show, search aside: what decides the empty screen and the headers. */
    private val all: StateFlow<ListsTabSections?> = combine(
        lists.observeAllLists(),
        users.observeByRelation(UserRelation.Friend),
        users.myUserId,
    ) { stored, friends, myId -> ListsTabSections.of(stored, myId, friends) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    private val _query: MutableStateFlow<String> = MutableStateFlow("")
    val query: StateFlow<String> = _query.asStateFlow()

    /** `shouldShowPlaceholder(.lists)`: latched, so a pull-to-refresh never brings the placeholder back. */
    val hasSynced: StateFlow<Boolean> = syncStatus.domains
        .map { it[SyncStatus.Domain.Lists] in setOf(SyncStatus.State.Completed, SyncStatus.State.Failed) }
        .runningFold(false) { settled, now -> settled || now }
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    /** Neither a list of mine nor one of my friends': the empty screen. */
    val hasNoList: StateFlow<Boolean> = all.map { it?.isEmpty ?: true }
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

    /** The headers show only when there is a network to set mine apart from. */
    val showsHeaders: StateFlow<Boolean> = all.map { it?.network?.isNotEmpty() == true }
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val rows: StateFlow<Rows> = combine(
        all,
        _query,
        ListRowFeed(entities, viewModelScope).images(all.map { it?.lists.orEmpty() }),
    ) { sections, query, images ->
        val shown: ListsTabSections = sections?.matching(query) ?: return@combine Rows()
        Rows(
            mine = shown.mine.map { ListsPresentation.row(it, images) },
            network = shown.network.map { ListsPresentation.row(it.list, images, it.owner) },
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, Rows())

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
