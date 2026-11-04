package studio.lunabee.nouveaurecit.ui.network

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.ui.lists.ListRowFeed
import studio.lunabee.nouveaurecit.ui.lists.ListRowModel

class UserViewModel(private val container: AppContainer, val userId: String) : ViewModel() {
    val user: StateFlow<UserEntity?> = container.users.observeUser(userId).stateIn(viewModelScope, SharingStarted.Eagerly, null)

    val myUserId: StateFlow<String?> = container.users.myUserId

    val items: StateFlow<List<ItemRow>> = container.inventory.observeItemsOf(userId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val shelves: StateFlow<List<ShelfWithItems>> = container.shelves.observeShelvesOf(userId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /** `OwnedItemCountText`: my own count, read from the store so it moves with every add and delete. */
    val localItemCount: StateFlow<Int> = container.inventory.observeCountOf(userId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    val firstSyncProgress: StateFlow<Map<String, SyncStatus.Progress>> = container.syncStatus.firstSyncProgress

    /** The Listes page: mine on my own profile, theirs on anyone else's, by name. */
    val lists: StateFlow<List<ListRowModel>> = ListRowFeed(container.entities, viewModelScope)
        .rows(container.lists.observeListsOf(userId))
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _listsLoad: MutableStateFlow<UserListsLoad> = MutableStateFlow(UserListsLoad.Loading)

    /** Loading too while an invitation from them is being accepted: the accept brings their lists. */
    val listsLoad: StateFlow<UserListsLoad> = combine(_listsLoad, container.session.friendsSyncing) { load, syncing ->
        if (userId in syncing) UserListsLoad.Loading else load
    }.stateIn(viewModelScope, SharingStarted.Eagerly, UserListsLoad.Loading)

    val actions: RelationActions = RelationActions(container, viewModelScope)

    init {
        viewModelScope.launch {
            // A reader met through a link the store has never held: fetch them once, the Flow does the rest.
            val stored: Flow<UserEntity?> = container.users.observeUser(userId)
            if (stored.first() == null) runCatching { container.users.getOrFetchUsers(listOf(userId)) }
            syncLists(stored.first())
        }
    }

    /**
     * A friend's lists are fetched each time their profile opens — not at launch, where every friend's
     * would be, for a page most profiles are never turned to. What the store holds shows meanwhile. Mine
     * are synced at launch with the rest of my data, and nobody else's are visible.
     */
    private suspend fun syncLists(user: UserEntity?) {
        if (user == null || user.id == myUserId.value || user.relation != UserRelation.Friend) {
            _listsLoad.value = UserListsLoad.Loaded
            return
        }
        _listsLoad.value = try {
            container.lists.syncFriendLists(user.id)
            UserListsLoad.Loaded
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            UserListsLoad.Failed
        }
    }
}
