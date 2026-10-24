package studio.lunabee.nouveaurecit.data.groups

import studio.lunabee.nouveaurecit.network.ImageUrl
import studio.lunabee.nouveaurecit.network.dto.GroupDto

/**
 * `ReaderGroup`: a group of readers on inventaire.io — a club, a family, a building — who share
 * their books.
 *
 * **A value, not a Room row.** Groups are held in memory by `GroupRepository` for the launch, as
 * iOS did until its feature 0035: a table would be a schema migration. A group's members are
 * `UserEntity` rows of the store, looked up by id.
 *
 * **The transitions are the server's.** [applying] reproduces `groupMembershipActions` in
 * `server/models/group.ts`, down to its shortcuts: a request to an open group lets you in, a request
 * from someone invited or who declined lets them in, an invitation to someone who had asked accepts
 * them. That is what lets every gesture be optimistic (ADR 0001): the state it shows is the state
 * the server is about to write, and a refusal puts the previous value back.
 */
data class ReaderGroup(
    val id: String,
    val name: String,
    val slug: String? = null,
    val description: String = "",
    val pictureUrl: String? = null,
    /** Whether any reader can find it in the search. */
    val searchable: Boolean = true,
    /** Whether a request lets you in at once, rather than waiting on an admin. */
    val open: Boolean = false,
    val admins: List<GroupMembership> = emptyList(),
    val members: List<GroupMembership> = emptyList(),
    val invited: List<GroupMembership> = emptyList(),
    val declined: List<GroupMembership> = emptyList(),
    val requested: List<GroupMembership> = emptyList(),
) {
    /** The one role [userId] holds, or `null` for someone the group does not know. */
    fun role(of: String?): GroupRole? {
        val userId: String = of ?: return null
        return when {
            admins.any { it.user == userId } -> GroupRole.Admin
            members.any { it.user == userId } -> GroupRole.Member
            invited.any { it.user == userId } -> GroupRole.Invited
            requested.any { it.user == userId } -> GroupRole.Requested
            declined.any { it.user == userId } -> GroupRole.Declined
            else -> null
        }
    }

    /**
     * The requests to join waiting on [userId] — all of them if they administer the group, none
     * otherwise: only an admin can answer one.
     */
    fun requestsToReview(by: String?): Int = if (role(of = by) == GroupRole.Admin) requested.size else 0

    /** Admins first, then members: everyone the group's books are shared with. */
    val memberIds: List<String> get() = admins.map { it.user } + members.map { it.user }

    val memberCount: Int get() = admins.size + members.size

    /**
     * Everyone named anywhere in the document, invitors included — what has to be in the store for
     * the screens to put a name on each line.
     */
    val everyoneIds: Set<String>
        get() {
            val memberships: List<GroupMembership> = admins + members + invited + declined + requested
            return (memberships.map { it.user } + memberships.mapNotNull { it.invitor }).toSet()
        }

    /** Who invited [userId], when they are waiting on an invitation. */
    fun invitor(of: String): String? = invited.firstOrNull { it.user == of }?.invitor

    /**
     * `server/controllers/groups/lib/leave_groups.ts`: anyone may leave, except the only admin of a
     * group that still has members — they have to name another admin first.
     */
    fun canLeave(userId: String): Boolean {
        if (admins.none { it.user == userId }) return true
        return admins.size > 1 || members.isEmpty()
    }

    /**
     * The group as it will be once [by] has made [action], to [on] when the gesture is about someone
     * else.
     *
     * Throws a [GroupTransitionError] when the server would refuse, so that nothing optimistic is
     * shown for a gesture that cannot succeed. Rights — who is admin enough to do what — are left to
     * the screens, which only offer a gesture to someone allowed to make it.
     */
    fun applying(
        action: GroupAction,
        by: String,
        on: String? = null,
        at: Double = System.currentTimeMillis().toDouble(),
    ): ReaderGroup = when (action) {
        GroupAction.Invite -> {
            val target: String = on ?: throw GroupTransitionError.MissingTarget()
            when (role(of = target)) {
                GroupRole.Requested -> moving(target, from = GroupRole.Requested, to = GroupRole.Member)
                GroupRole.Declined -> throw GroupTransitionError.AlreadyDeclined()
                null -> copy(invited = invited + GroupMembership(user = target, invitor = by, timestamp = at))
                else -> throw GroupTransitionError.AlreadyInGroup()
            }
        }
        GroupAction.Accept -> moving(by, from = GroupRole.Invited, to = GroupRole.Member)
        GroupAction.Decline -> moving(by, from = GroupRole.Invited, to = GroupRole.Declined)
        GroupAction.Request -> when (role(of = by)) {
            GroupRole.Invited -> moving(by, from = GroupRole.Invited, to = GroupRole.Member)
            GroupRole.Declined -> moving(by, from = GroupRole.Declined, to = GroupRole.Member)
            null -> {
                val membership: GroupMembership = GroupMembership(user = by, invitor = null, timestamp = at)
                if (open) copy(members = members + membership) else copy(requested = requested + membership)
            }
            else -> throw GroupTransitionError.AlreadyInGroup()
        }
        GroupAction.CancelRequest -> removing(by, from = GroupRole.Requested)
        GroupAction.AcceptRequest -> moving(on ?: throw GroupTransitionError.MissingTarget(), from = GroupRole.Requested, to = GroupRole.Member)
        GroupAction.RefuseRequest -> removing(on ?: throw GroupTransitionError.MissingTarget(), from = GroupRole.Requested)
        GroupAction.MakeAdmin -> moving(on ?: throw GroupTransitionError.MissingTarget(), from = GroupRole.Member, to = GroupRole.Admin)
        GroupAction.Kick -> removing(on ?: throw GroupTransitionError.MissingTarget(), from = GroupRole.Member)
        GroupAction.Leave -> {
            if (!canLeave(by)) throw GroupTransitionError.LastAdmin()
            removing(by, from = if (role(of = by) == GroupRole.Admin) GroupRole.Admin else GroupRole.Member)
        }
    }

    private fun moving(userId: String, from: GroupRole, to: GroupRole): ReaderGroup {
        val membership: GroupMembership = list(from).firstOrNull { it.user == userId } ?: throw GroupTransitionError.NotInExpectedRole()
        val removed: ReaderGroup = replacing(from, list(from) - membership)
        return removed.replacing(to, removed.list(to) + membership)
    }

    private fun removing(userId: String, from: GroupRole): ReaderGroup {
        val membership: GroupMembership = list(from).firstOrNull { it.user == userId } ?: throw GroupTransitionError.NotInExpectedRole()
        return replacing(from, list(from) - membership)
    }

    private fun list(role: GroupRole): List<GroupMembership> = when (role) {
        GroupRole.Admin -> admins
        GroupRole.Member -> members
        GroupRole.Invited -> invited
        GroupRole.Declined -> declined
        GroupRole.Requested -> requested
    }

    private fun replacing(role: GroupRole, list: List<GroupMembership>): ReaderGroup = when (role) {
        GroupRole.Admin -> copy(admins = list)
        GroupRole.Member -> copy(members = list)
        GroupRole.Invited -> copy(invited = list)
        GroupRole.Declined -> copy(declined = list)
        GroupRole.Requested -> copy(requested = list)
    }

    companion object {
        /** inventaire.io leaves out what a group does not have, and older documents predate `open`. */
        fun of(dto: GroupDto): ReaderGroup = ReaderGroup(
            id = dto.id,
            name = dto.name,
            slug = dto.slug,
            description = dto.description.orEmpty(),
            // Served as `/img/groups/<hash>` on inventaire.io.
            pictureUrl = ImageUrl.absolute(dto.picture),
            searchable = dto.searchable ?: true,
            open = dto.open ?: false,
            admins = dto.admins,
            members = dto.members,
            invited = dto.invited.orEmpty(),
            declined = dto.declined.orEmpty(),
            requested = dto.requested.orEmpty(),
        )
    }
}
