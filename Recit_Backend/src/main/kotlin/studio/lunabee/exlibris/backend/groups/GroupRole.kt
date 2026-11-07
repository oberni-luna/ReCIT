package studio.lunabee.exlibris.backend.groups

/**
 * Where a reader stands in a group: one of inventaire.io's five lists, [listName] the key of the group document,
 * [storedName] a `group_memberships.role`.
 */
enum class GroupRole(
    val storedName: String,
    val listName: String,
) {
    ADMIN("admin", "admins"),
    MEMBER("member", "members"),
    INVITED("invited", "invited"),
    DECLINED("declined", "declined"),
    REQUESTED("requested", "requested"),
    ;

    /** inventaire.io's `groupCategories.members`: who is in the group, as opposed to waiting at its door. */
    val isInGroup: Boolean
        get() = this == ADMIN || this == MEMBER

    companion object {
        fun of(storedName: String): GroupRole =
            requireNotNull(entries.firstOrNull { it.storedName == storedName }) { "unknown group role $storedName" }
    }
}
