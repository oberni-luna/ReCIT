package studio.lunabee.nouveaurecit.ui.network.groups

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.groups.MyGroups
import studio.lunabee.nouveaurecit.data.groups.group
import studio.lunabee.nouveaurecit.ui.network.NetworkSegment

class GroupsSegmentStateTest {
    private val some: MyGroups = MyGroups.of(listOf(group(admins = listOf("me"))), me = "me")

    @Test
    fun groupsWinOverEverything() {
        assertEquals(GroupsSegmentState.Groups, groupsSegmentState(some, hasLoaded = false, domain = SyncStatus.State.Running))
        assertEquals(GroupsSegmentState.Groups, groupsSegmentState(some, hasLoaded = true, domain = SyncStatus.State.Failed))
    }

    @Test
    fun noGroupSaysNothingBeforeTheFirstAnswer() {
        assertEquals(GroupsSegmentState.Syncing, groupsSegmentState(MyGroups.Empty, hasLoaded = false, domain = null))
        assertEquals(GroupsSegmentState.Syncing, groupsSegmentState(MyGroups.Empty, hasLoaded = false, domain = SyncStatus.State.Running))
        assertEquals(GroupsSegmentState.Failed, groupsSegmentState(MyGroups.Empty, hasLoaded = false, domain = SyncStatus.State.Failed))
    }

    @Test
    fun onceLoadedNoGroupIsTheEmptyStateEvenWhileRefreshing() {
        assertEquals(GroupsSegmentState.Empty, groupsSegmentState(MyGroups.Empty, hasLoaded = true, domain = SyncStatus.State.Running))
        assertEquals(GroupsSegmentState.Empty, groupsSegmentState(MyGroups.Empty, hasLoaded = true, domain = SyncStatus.State.Failed))
    }

    @Test
    fun theTabReopensOnTheSegmentChosenLastAndOnAmisOtherwise() {
        assertEquals(NetworkSegment.Groups, NetworkSegment.restored("Groups"))
        assertEquals(NetworkSegment.Friends, NetworkSegment.restored("Friends"))
        assertEquals(NetworkSegment.Friends, NetworkSegment.restored(null))
        assertEquals(NetworkSegment.Friends, NetworkSegment.restored("All"))
    }
}
