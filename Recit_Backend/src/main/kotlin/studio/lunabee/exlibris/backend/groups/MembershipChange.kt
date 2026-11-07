package studio.lunabee.exlibris.backend.groups

/** One row of `group_memberships` to write, what an action decided; `GroupsRepository.transition` writes it. */
sealed interface MembershipChange {
    val userId: String

    /** A new membership, timestamped now. */
    data class Add(
        override val userId: String,
        val role: GroupRole,
        val invitor: String?,
    ) : MembershipChange

    /** The membership to [role], appended to its list; [invitor] replaces the one it had when given. */
    data class Move(
        override val userId: String,
        val role: GroupRole,
        val invitor: String? = null,
    ) : MembershipChange

    data class Remove(
        override val userId: String,
    ) : MembershipChange
}
