package studio.lunabee.nouveaurecit.ui.network.groups

import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.groups.MyGroups

/** What the Groupes segment shows (`GroupsSegmentView`). */
enum class GroupsSegmentState { Syncing, Failed, Empty, Groups }

/**
 * The groups win over everything; with none, an empty map says nothing before the first answer —
 * nothing is kept across launches. So the segment spins until the groups have loaded once, says so
 * when that first sync failed, and only then says I am in no group.
 */
fun groupsSegmentState(groups: MyGroups, hasLoaded: Boolean, domain: SyncStatus.State?): GroupsSegmentState = when {
    !groups.isEmpty -> GroupsSegmentState.Groups
    hasLoaded -> GroupsSegmentState.Empty
    domain == SyncStatus.State.Failed -> GroupsSegmentState.Failed
    else -> GroupsSegmentState.Syncing
}
