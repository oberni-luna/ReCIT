package studio.lunabee.nouveaurecit.ui.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.model.UserRelation

class NetworkLogicTest {
    @Test
    fun firstSyncStateIsSyncedOnceTheInventoryHasLanded() {
        assertEquals(FirstSyncState.Synced, FirstSyncState.of(lastInventorySync = 1.0, progress = SyncStatus.Progress(3, 10)))
    }

    @Test
    fun firstSyncStateIsRunningWhileAProgressIsHeld() {
        val progress: SyncStatus.Progress = SyncStatus.Progress(received = 2, announced = 8)
        assertEquals(FirstSyncState.Running(progress), FirstSyncState.of(lastInventorySync = null, progress = progress))
    }

    @Test
    fun firstSyncStateIsWaitingBeforeTheFriendsTurn() {
        assertEquals(FirstSyncState.Waiting, FirstSyncState.of(lastInventorySync = null, progress = null))
    }

    @Test
    fun friendsWinOverTheSyncingRow() {
        assertEquals(FriendsSectionState.Friends, friendsSectionState(SyncStatus.State.Running, friendCount = 2))
    }

    @Test
    fun anEmptyNetworkShowsTheSyncingRowUntilTheCommunityDomainIsDone() {
        assertEquals(FriendsSectionState.Syncing, friendsSectionState(null, friendCount = 0))
        assertEquals(FriendsSectionState.Syncing, friendsSectionState(SyncStatus.State.Idle, friendCount = 0))
        assertEquals(FriendsSectionState.Syncing, friendsSectionState(SyncStatus.State.Running, friendCount = 0))
        assertEquals(FriendsSectionState.Empty, friendsSectionState(SyncStatus.State.Completed, friendCount = 0))
        assertEquals(FriendsSectionState.Empty, friendsSectionState(SyncStatus.State.Failed, friendCount = 0))
    }

    @Test
    fun readerTrailingFollowsTheRelation() {
        assertEquals(ReaderTrailing.Add, readerTrailing(UserRelation.None))
        assertEquals(ReaderTrailing.Sent, readerTrailing(UserRelation.RequestSent))
        assertEquals(ReaderTrailing.Received, readerTrailing(UserRelation.RequestReceived))
        assertEquals(ReaderTrailing.Nothing, readerTrailing(UserRelation.Friend))
    }

    @Test
    fun inventoryIsShownForMeAndForFriendsOnly() {
        assertTrue(showsInventory("me", myUserId = "me", relation = UserRelation.None))
        assertTrue(showsInventory("ann", myUserId = "me", relation = UserRelation.Friend))
        assertFalse(showsInventory("ann", myUserId = "me", relation = UserRelation.RequestSent))
        assertFalse(showsInventory("ann", myUserId = null, relation = UserRelation.RequestReceived))
    }

    @Test
    fun searchPlaceholderPhases() {
        assertEquals(ReaderSearchPlaceholder.Initial, ReaderSearchState().placeholder)
        assertEquals(ReaderSearchPlaceholder.Searching, ReaderSearchState(query = "an", isSearching = true, hasSearched = true).placeholder)
        assertEquals(ReaderSearchPlaceholder.NoResults, ReaderSearchState(query = "an", hasSearched = true).placeholder)
    }

    @Test
    fun aBlankQueryIsNotQuerying() {
        assertFalse(ReaderSearchState(query = "   ").isQuerying)
        assertTrue(ReaderSearchState(query = " a ").isQuerying)
    }

    @Test
    fun pendingRequestsReplaceTheExplanationAtRest() {
        assertFalse(ReaderSearchState().showsPlaceholder(pendingCount = 2))
        assertTrue(ReaderSearchState().showsPlaceholder(pendingCount = 0))
    }

    @Test
    fun typingBringsThePlaceholderBackOverPendingRequests() {
        assertTrue(ReaderSearchState(query = "an").showsPlaceholder(pendingCount = 2))
        assertFalse(ReaderSearchState(query = "an", resultIds = listOf("u1")).showsPlaceholder(pendingCount = 2))
    }
}
