package studio.lunabee.exlibris.backend.groups

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException

/**
 * What each membership action does to a group, inventaire.io's `groupMembershipActions` (`models/group.ts`), once
 * [MembershipRights] let it through, with its refusals: a membership looked for and missing is `403`, one that
 * already exists is a `200` error, which the apps take as done.
 */
object MembershipMoves {
    /** inventaire.io promotes this many of the most senior members when an account deletion leaves no admin. */
    private const val PROMOTED_ON_DEPARTURE: Int = 3

    fun change(
        action: GroupMembershipAction,
        group: GroupRecord,
        actorId: String,
        targetId: String?,
    ): List<MembershipChange> {
        val target: String by lazy { requireNotNull(targetId) { "${action.path} names no user" } }
        return when (action) {
            GroupMembershipAction.INVITE -> invite(group, actorId, target)
            GroupMembershipAction.ACCEPT -> move(group, actorId, GroupRole.INVITED, GroupRole.MEMBER)
            GroupMembershipAction.DECLINE -> move(group, actorId, GroupRole.INVITED, GroupRole.DECLINED)
            GroupMembershipAction.REQUEST -> request(group, actorId)
            GroupMembershipAction.CANCEL_REQUEST -> remove(group, actorId, GroupRole.REQUESTED)
            GroupMembershipAction.ACCEPT_REQUEST -> move(group, target, GroupRole.REQUESTED, GroupRole.MEMBER)
            GroupMembershipAction.REFUSE_REQUEST -> remove(group, target, GroupRole.REQUESTED)
            GroupMembershipAction.MAKE_ADMIN -> move(group, target, GroupRole.MEMBER, GroupRole.ADMIN)
            GroupMembershipAction.KICK -> remove(group, target, GroupRole.MEMBER)
            GroupMembershipAction.LEAVE -> remove(group, actorId, group.roleOf(actorId) ?: GroupRole.MEMBER)
        }
    }

    /**
     * An account deleted leaves every group it is named in, whatever its role, as inventaire.io's `leaveAllGroups`:
     * a group it leaves without an admin gets its three most senior members as admins, or ends when none is left.
     */
    fun departure(
        group: GroupRecord,
        userId: String,
    ): List<MembershipChange> {
        val remainingAdmins: List<GroupMembership> = group.inRole(GroupRole.ADMIN).filter { it.userId != userId }
        val promoted: List<MembershipChange> =
            if (remainingAdmins.isEmpty()) {
                group
                    .inRole(GroupRole.MEMBER)
                    .filter { it.userId != userId }
                    .sortedBy { it.timestamp }
                    .take(PROMOTED_ON_DEPARTURE)
                    .map { MembershipChange.Move(it.userId, GroupRole.ADMIN) }
            } else {
                emptyList()
            }
        return listOf(MembershipChange.Remove(userId)) + promoted
    }

    /** A reader who had asked to join is let in by an invitation, as an accepted request. */
    private fun invite(
        group: GroupRecord,
        invitorId: String,
        invitedId: String,
    ): List<MembershipChange> =
        when (group.roleOf(invitedId)) {
            null -> listOf(MembershipChange.Add(invitedId, GroupRole.INVITED, invitorId))
            GroupRole.REQUESTED -> listOf(MembershipChange.Move(invitedId, GroupRole.MEMBER, invitorId))
            GroupRole.DECLINED -> throw ApiException(HttpStatusCode.BadRequest, "user already declined the invitation")
            else -> throw alreadyExists()
        }

    /** A reader invited, or who declined, is let in by asking; an open group lets anyone in. */
    private fun request(
        group: GroupRecord,
        userId: String,
    ): List<MembershipChange> =
        when (group.roleOf(userId)) {
            null -> {
                val role: GroupRole = if (group.open) GroupRole.MEMBER else GroupRole.REQUESTED
                listOf(MembershipChange.Add(userId, role, invitor = null))
            }

            GroupRole.INVITED, GroupRole.DECLINED -> {
                listOf(MembershipChange.Move(userId, GroupRole.MEMBER))
            }

            else -> {
                throw alreadyExists()
            }
        }

    private fun move(
        group: GroupRecord,
        userId: String,
        from: GroupRole,
        to: GroupRole,
    ): List<MembershipChange> {
        requireRole(group, userId, from)
        return listOf(MembershipChange.Move(userId, to))
    }

    private fun remove(
        group: GroupRecord,
        userId: String,
        from: GroupRole,
    ): List<MembershipChange> {
        requireRole(group, userId, from)
        return listOf(MembershipChange.Remove(userId))
    }

    private fun requireRole(
        group: GroupRecord,
        userId: String,
        role: GroupRole,
    ) {
        if (group.roleOf(userId) != role) throw ApiException(HttpStatusCode.Forbidden, "membership not found")
    }

    private fun alreadyExists(): ApiException = ApiException(HttpStatusCode.OK, "membership already exist")
}
