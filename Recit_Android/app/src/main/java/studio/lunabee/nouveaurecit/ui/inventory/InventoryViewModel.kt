package studio.lunabee.nouveaurecit.ui.inventory

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity

/** `ShelvesView` + `ShelvesContent`'s state: my user, my shelves and copies, the first-sync banner. */
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

    val syncState: StateFlow<FirstSyncState> = combine(myUser, container.syncStatus.firstSyncProgress) { user, progress ->
        if (user == null) FirstSyncState.Synced else FirstSyncState.from(user.lastInventorySync, progress[user.id])
    }.stateIn(viewModelScope, SharingStarted.Eagerly, FirstSyncState.Synced)

    private val _isRefreshing: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

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
}
