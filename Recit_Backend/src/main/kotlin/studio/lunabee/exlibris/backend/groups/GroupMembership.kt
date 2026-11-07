package studio.lunabee.exlibris.backend.groups

/**
 * One reader's place in a group, inventaire.io's `{user, invitor, timestamp}`: [invitor] is `null` for the creator
 * and for a request, [timestamp] the membership's creation, kept when it moves between roles.
 */
data class GroupMembership(
    val userId: String,
    val role: GroupRole,
    val invitor: String?,
    val timestamp: Long,
)
