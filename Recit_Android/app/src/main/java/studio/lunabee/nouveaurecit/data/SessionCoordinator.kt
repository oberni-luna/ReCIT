package studio.lunabee.nouveaurecit.data

import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import studio.lunabee.nouveaurecit.auth.AuthRepository
import studio.lunabee.nouveaurecit.auth.model.SessionExpiry
import studio.lunabee.nouveaurecit.data.db.UserEntity

/**
 * `RootView+RefreshUserData` and `RootView+ForgetSignedOutUser`: the sync order of a signed-in
 * launch, and what a signed-out one forgets.
 *
 * Order: my user → my shelves → my inventory → relations → lists → each friend's shelves then
 * inventory, never-synced friends first. A `401` on the first call is the only thing that signs
 * the user out (ADR 0008); every later failure is logged and the next domain carries on.
 */
class SessionCoordinator(
    private val scope: CoroutineScope,
    private val auth: AuthRepository,
    private val users: UserRepository,
    private val shelves: ShelfRepository,
    private val inventory: InventoryRepository,
    private val lists: ListRepository,
    private val syncStatus: SyncStatus,
) {
    private val mutex: Mutex = Mutex()

    fun refreshUserData(): Job = scope.launch { refresh() }

    /** Suspends until the sync is over — what pull-to-refresh waits on. */
    suspend fun refresh() = mutex.withLock {
        if (!auth.isAuthenticated.value) return@withLock
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
        sync(SyncStatus.Domain.Lists) { lists.syncLists(me) }
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

    /** A friend just accepted: their books arrive now rather than at the next launch. */
    fun syncFriend(userId: String): Job = scope.launch {
        val friend: UserEntity = users.getOrFetchUsers(listOf(userId)).firstOrNull() ?: return@launch
        runCatching { shelves.syncShelves(friend) }
        runCatching { inventory.syncInventory(friend) }
    }

    suspend fun signOut() {
        auth.logout()
        forgetSignedOutUser()
    }

    suspend fun forgetSignedOutUser() {
        syncStatus.reset()
        runCatching { users.wipeUserData() }.onFailure { Log.w(TAG, "wipe failed", it) }
    }

    /** `DELETE /api/user`; on success the store is wiped whole and the session forgotten, not logged out. */
    suspend fun deleteAccount() {
        users.deleteAccount()
        syncStatus.reset()
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
