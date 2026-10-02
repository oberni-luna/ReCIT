package studio.lunabee.nouveaurecit.ui.network

import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.model.UserRelation

/**
 * `InventoryFirstSyncState`: where a user's very first inventory sync stands. [Synced] once
 * `lastInventorySync` is set; [Running] while [SyncStatus] holds a progress for them; [Waiting]
 * for a friend whose turn has not come yet.
 */
sealed interface FirstSyncState {
    data object Synced : FirstSyncState

    data object Waiting : FirstSyncState

    data class Running(val progress: SyncStatus.Progress) : FirstSyncState

    companion object {
        fun of(lastInventorySync: Double?, progress: SyncStatus.Progress?): FirstSyncState = when {
            lastInventorySync != null -> Synced
            progress != null -> Running(progress)
            else -> Waiting
        }
    }
}

/** What the « Amis » section shows (`FriendsSegmentView`). */
enum class FriendsSectionState { Syncing, Empty, Friends }

/**
 * iOS shows the syncing row until the Community domain has completed a first sync *ever* (the
 * marker is persisted). Android's [SyncStatus] lives in memory and goes back to `Running` on every
 * refresh, so the friends already in Room win over the row: the row only stands in for an empty
 * list while the domain has not finished.
 */
fun friendsSectionState(community: SyncStatus.State?, friendCount: Int): FriendsSectionState = when {
    friendCount > 0 -> FriendsSectionState.Friends
    community == null || community == SyncStatus.State.Idle || community == SyncStatus.State.Running -> FriendsSectionState.Syncing
    else -> FriendsSectionState.Empty
}

/** `ReaderRowView.trailing`: the control at the end of a reader's line. */
enum class ReaderTrailing { Add, Sent, Received, Nothing }

fun readerTrailing(relation: UserRelation): ReaderTrailing = when (relation) {
    UserRelation.None -> ReaderTrailing.Add
    UserRelation.RequestSent -> ReaderTrailing.Sent
    UserRelation.RequestReceived -> ReaderTrailing.Received
    UserRelation.Friend -> ReaderTrailing.Nothing
}

/** Mine, or a friend's: the two cases where a profile has books to show (`UserDetailView.showsInventory`). */
fun showsInventory(userId: String, myUserId: String?, relation: UserRelation): Boolean =
    userId == myUserId || relation == UserRelation.Friend

/** `ReaderSearchView`'s placeholder, when there are no results to list. */
enum class ReaderSearchPlaceholder { Searching, NoResults, Initial }

/**
 * The search screen's whole state: the query as typed, the results of the last search that came
 * back for it, and whether one is in flight.
 */
data class ReaderSearchState(
    val query: String = "",
    val resultIds: List<String> = emptyList(),
    val isSearching: Boolean = false,
    val hasSearched: Boolean = false,
) {
    /** True from the first character typed: « Demandes en cours » goes as the field fills. */
    val isQuerying: Boolean get() = query.isNotBlank()

    val placeholder: ReaderSearchPlaceholder
        get() = when {
            isSearching -> ReaderSearchPlaceholder.Searching
            hasSearched -> ReaderSearchPlaceholder.NoResults
            else -> ReaderSearchPlaceholder.Initial
        }

    /**
     * With no results, the explanation gives way to the pending requests; with none in flight it
     * is the whole screen.
     */
    fun showsPlaceholder(pendingCount: Int): Boolean = resultIds.isEmpty() && (isQuerying || pendingCount == 0)
}
