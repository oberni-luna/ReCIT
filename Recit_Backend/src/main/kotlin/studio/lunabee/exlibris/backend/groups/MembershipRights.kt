package studio.lunabee.exlibris.backend.groups

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException

/**
 * Who may take which membership action, inventaire.io's `membership_validations.ts`, with its words and statuses:
 * checked before [MembershipMoves] says what the action does. `accept` and `decline` check nothing here: without an
 * invitation, the move itself refuses.
 */
object MembershipRights {
    fun check(
        action: GroupMembershipAction,
        group: GroupRecord,
        actorId: String,
        targetId: String?,
    ) {
        refusal(action, group, actorId, targetId)?.let { throw it }
    }

    /** `update-settings`, `make-admin` and `kick` are an admin's. */
    fun requireAdmin(role: GroupRole?) {
        adminRefusal(role)?.let { throw it }
    }

    private fun refusal(
        action: GroupMembershipAction,
        group: GroupRecord,
        actorId: String,
        targetId: String?,
    ): ApiException? {
        val actor: GroupRole? = group.roleOf(actorId)
        val target: GroupRole? = targetId?.let(group::roleOf)
        return when (action) {
            GroupMembershipAction.INVITE -> {
                refuseIf(actor?.isInGroup != true, "invitor isn't in group")
            }

            GroupMembershipAction.ACCEPT_REQUEST, GroupMembershipAction.REFUSE_REQUEST -> {
                refuseIf(actor != GroupRole.ADMIN, "user is not admin")
                    ?: ApiException(HttpStatusCode.Unauthorized, "request not found").takeIf {
                        target != GroupRole.REQUESTED
                    }
            }

            GroupMembershipAction.MAKE_ADMIN -> {
                adminRefusal(actor)
            }

            GroupMembershipAction.KICK -> {
                adminRefusal(actor) ?: refuseIf(target == GroupRole.ADMIN, "target user is also a group admin")
            }

            GroupMembershipAction.LEAVE -> {
                leavingRefusal(group, actor)
            }

            GroupMembershipAction.REQUEST -> {
                refuseIf(actor?.isInGroup == true || actor == GroupRole.REQUESTED, "user is already in group")
            }

            GroupMembershipAction.CANCEL_REQUEST -> {
                refuseIf(actor != GroupRole.REQUESTED, "request not found")
            }

            GroupMembershipAction.ACCEPT, GroupMembershipAction.DECLINE -> {
                null
            }
        }
    }

    private fun adminRefusal(role: GroupRole?): ApiException? =
        refuseIf(role != GroupRole.ADMIN, "user is not a group admin")

    /** inventaire.io's `userCanLeaveGroup`: the only admin of a group that still has members names another first. */
    private fun leavingRefusal(
        group: GroupRecord,
        actor: GroupRole?,
    ): ApiException? {
        val isOnlyAdmin: Boolean = actor == GroupRole.ADMIN && group.inRole(GroupRole.ADMIN).size == 1
        return refuseIf(actor?.isInGroup != true, "user is not in the group")
            ?: refuseIf(
                isOnlyAdmin && group.inRole(GroupRole.MEMBER).isNotEmpty(),
                "the last group admin can't leave before naming another admin",
            )
    }

    private fun refuseIf(
        condition: Boolean,
        verbose: String,
    ): ApiException? = if (condition) ApiException(HttpStatusCode.Forbidden, verbose) else null
}
