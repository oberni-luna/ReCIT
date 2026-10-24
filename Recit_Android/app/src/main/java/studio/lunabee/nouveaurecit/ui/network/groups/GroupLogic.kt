package studio.lunabee.nouveaurecit.ui.network.groups

import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.GroupSearchResult

/**
 * `GroupActionsView.hasContent`: whether the panel under a group's header has anything to show for
 * [myRole]. A member who may leave has neither a button nor a note, and the screen leaves the panel
 * out rather than give it an empty gap.
 */
fun groupActionsHaveContent(myRole: GroupRole?, canLeave: Boolean): Boolean = when (myRole) {
    null, GroupRole.Declined, GroupRole.Requested, GroupRole.Invited -> true
    GroupRole.Admin, GroupRole.Member -> !canLeave
}

/** `FindGroupsView`'s placeholder, when there are no results to list. */
enum class GroupSearchPlaceholder { Searching, NoResults, Initial }

/** The group search's whole state: the query as typed, the last results that came back for it, and whether one is in flight. */
data class GroupSearchState(
    val query: String = "",
    val results: List<GroupSearchResult> = emptyList(),
    val isSearching: Boolean = false,
    val hasSearched: Boolean = false,
) {
    val placeholder: GroupSearchPlaceholder
        get() = when {
            isSearching -> GroupSearchPlaceholder.Searching
            hasSearched -> GroupSearchPlaceholder.NoResults
            else -> GroupSearchPlaceholder.Initial
        }
}

/** What ends a friend's line on « Inviter des amis », from where they stand in the group. */
enum class InviteTrailing { AlreadyMember, Sent, Declined, Accept, Invite }

/**
 * `InviteToGroupView.trailing`: a member is settled, an invitation waits, a refusal is final — and
 * inviting a friend who had asked to join accepts them, so the pill says « Accepter ».
 */
fun inviteTrailing(role: GroupRole?): InviteTrailing = when (role) {
    GroupRole.Admin, GroupRole.Member -> InviteTrailing.AlreadyMember
    GroupRole.Invited -> InviteTrailing.Sent
    GroupRole.Declined -> InviteTrailing.Declined
    GroupRole.Requested -> InviteTrailing.Accept
    null -> InviteTrailing.Invite
}
