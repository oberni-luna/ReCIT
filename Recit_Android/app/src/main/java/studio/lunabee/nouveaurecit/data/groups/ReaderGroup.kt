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
