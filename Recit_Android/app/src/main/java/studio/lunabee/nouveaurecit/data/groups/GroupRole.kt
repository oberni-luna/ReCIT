package studio.lunabee.nouveaurecit.data.groups

/**
 * `GroupRole`: the five lists a group document keeps people in (`server/models/attributes/group.ts`,
 * `groupRoles`). Someone is in at most one of them.
 */
enum class GroupRole {
    Admin,
    Member,

    /** Invited by a member, not answered yet. */
    Invited,

    /** Turned an invitation down. Cannot be invited again, but a request of theirs is accepted on the spot. */
    Declined,

    /** Asked to join a group that is not open, waiting on an admin. */
    Requested,
    ;

    /** Admins and members: the people the group's books are shared with. */
    val belongs: Boolean get() = this == Admin || this == Member
}
