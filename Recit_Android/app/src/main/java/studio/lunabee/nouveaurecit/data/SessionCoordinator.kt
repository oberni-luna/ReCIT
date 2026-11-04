package studio.lunabee.nouveaurecit.data

import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.getAndUpdate
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import studio.lunabee.nouveaurecit.auth.AuthRepository
import studio.lunabee.nouveaurecit.auth.model.SessionExpiry
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.sorting.SortSession

/**
 * `RootView+RefreshUserData` and `RootView+ForgetSignedOutUser`: the sync order of a signed-in
 * launch, and what a signed-out one forgets.
 *
 * Order: my user → my shelves → my inventory → relations → groups → lists → my friends' lists → each
 * friend's shelves then inventory, never-synced friends first. A `401` on the first call is the only thing that signs
 * the user out (ADR 0008); every later failure is logged and the next domain carries on.
 */
class SessionCoordinator(
    private val scope: CoroutineScope,
    private val auth: AuthRepository,
    private val users: UserRepository,
    private val groups: GroupRepository,
    private val shelves: ShelfRepository,
    private val inventory: InventoryRepository,
    private val lists: ListRepository,
    private val sortSession: SortSession,
    private val syncStatus: SyncStatus,
) {
    private val mutex: Mutex = Mutex()

    private val _friendsSyncing: MutableStateFlow<Set<String>> = MutableStateFlow(emptySet())

    /** The readers whose invitation I am accepting, while their books and lists come in. */
    val friendsSyncing: StateFlow<Set<String>> = _friendsSyncing.asStateFlow()

    fun refreshUserData(): Job = scope.launch { refresh() }

    /** Suspends until the sync is over — what pull-to-refresh waits on. */
    suspend fun refresh() = mutex.withLock {
        if (!auth.isAuthenticated.value) return@withLock
        runCatching { users.restoreMyUserId() }.onFailure { Log.w(TAG, "restore failed", it) }
        try {
            users.syncMyUser()
        } catch (error: Exception) {
            Log.w(TAG, "user sync failed", error)
            if (SessionExpiry.isSessionGone(error)) signOut()
            return@withLock
        }
        val me: UserEntity = users.myUser() ?: return@withLock
        sync(SyncStatus.Domain.Shelves) { shelves.syncShelves(me) }
        sync(SyncStatus.Domain.Inventory) { inventory.syncInventory(users.myUser() ?: me) }
        sync(SyncStatus.Domain.Community) { users.syncRelations() }
        sync(SyncStatus.Domain.Groups) { groups.syncMyGroups(me.id) }
        sync(SyncStatus.Domain.Lists) { lists.syncLists(me) }
        // Outside the tracking: the Lists tab's placeholder waits on my lists alone.
        runCatching { lists.syncNetworkLists(users.friends().map { it.id }) }.onFailure { Log.w(TAG, "network lists", it) }
        syncFriendsInventories()
    }

    private suspend fun syncFriendsInventories() {
        val friends: List<UserEntity> = users.friends().sortedBy { it.username.lowercase() }
        val queue: List<UserEntity> = friends.filter { it.lastInventorySync == null } + friends.filter { it.lastInventorySync != null }
        for (friend in queue) {
            runCatching { shelves.syncShelves(friend) }.onFailure { Log.w(TAG, "shelves of ${friend.username}", it) }
            runCatching { inventory.syncInventory(friend) }.onFailure { Log.w(TAG, "inventory of ${friend.username}", it) }
        }
    }

    /**
     * Accepts [userId]'s invitation, once: an accept already under way for them is not sent again. Until
     * the answer and the new friend's data are in, they are among [friendsSyncing], so their profile waits
     * on their lists rather than saying they have none.
     */
    suspend fun acceptFriend(userId: String) {
        val previous: Set<String> = _friendsSyncing.getAndUpdate { it + userId }
        if (userId in previous) return
        try {
            users.acceptRelation(userId) { syncFriend(userId).join() }.join()
        } finally {
            _friendsSyncing.update { it - userId }
        }
    }

    /** A friend just accepted: their books and lists arrive now rather than at the next launch. */
    private fun syncFriend(userId: String): Job = scope.launch {
        val friend: UserEntity = users.getOrFetchUsers(listOf(userId)).firstOrNull() ?: return@launch
        runCatching { shelves.syncShelves(friend) }
        runCatching { inventory.syncInventory(friend) }
        runCatching { lists.syncFriendLists(userId) }
    }

    suspend fun signOut() {
        auth.logout()
        forgetSignedOutUser()
    }

    suspend fun forgetSignedOutUser() {
        syncStatus.reset()
        groups.reset()
        // The sorting draft is the user's, like their étagères: the next account must not open on it.
        sortSession.reset()
        runCatching { users.wipeUserData() }.onFailure { Log.w(TAG, "wipe failed", it) }
    }

    /** `DELETE /api/user`; on success the store is wiped whole and the session forgotten, not logged out. */
    suspend fun deleteAccount() {
        users.deleteAccount()
        syncStatus.reset()
        groups.reset()
        sortSession.reset()
        auth.forgetSession()
    }

    private suspend fun sync(domain: SyncStatus.Domain, operation: suspend () -> Unit) {
        syncStatus.mark(domain, SyncStatus.State.Running)
        try {
            operation()
            syncStatus.mark(domain, SyncStatus.State.Completed)
        } catch (error: Exception) {
            Log.w(TAG, "$domain sync failed", error)
            syncStatus.mark(domain, SyncStatus.State.Failed)
        }
    }

    private companion object {
        const val TAG: String = "Sync"
    }
}
