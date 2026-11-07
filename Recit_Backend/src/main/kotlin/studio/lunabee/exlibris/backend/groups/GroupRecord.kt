package studio.lunabee.exlibris.backend.groups

import studio.lunabee.exlibris.backend.users.UserPosition

/** A `groups` row and its memberships, each role's in the order inventaire.io's lists grew in. */
data class GroupRecord(
    val id: String,
    val version: Int,
    val name: String,
    val slug: String,
    val description: String,
    val searchable: Boolean,
    val open: Boolean,
    val picture: String?,
    val position: UserPosition?,
    val creator: String,
    val created: Long,
    val memberships: List<GroupMembership>,
) {
    fun roleOf(userId: String): GroupRole? = memberships.firstOrNull { it.userId == userId }?.role

    fun inRole(role: GroupRole): List<GroupMembership> = memberships.filter { it.role == role }

    /** inventaire.io's `getAllGroupMembersIds`: admins, then members. */
    val memberIds: List<String>
        get() = inRole(GroupRole.ADMIN).map { it.userId } + inRole(GroupRole.MEMBER).map { it.userId }
}
