package studio.lunabee.exlibris.backend.groups

/** What became of a group once memberships changed. */
sealed interface GroupTransition {
    data object Kept : GroupTransition

    /**
     * Its last admin gone, the group is deleted with its memberships, as inventaire.io's `deleteGroupIfEmpty`;
     * [picture] is the one it had, to release.
     */
    data class Ended(
        val picture: String?,
    ) : GroupTransition
}
