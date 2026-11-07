package studio.lunabee.exlibris.backend.groups

import studio.lunabee.exlibris.backend.users.UserPosition

/** One attribute `update-settings` changes, inventaire.io's `updatable`, its value already checked. */
sealed interface GroupSetting {
    data class Name(
        val value: String,
    ) : GroupSetting

    data class Description(
        val value: String,
    ) : GroupSetting

    data class Searchable(
        val value: Boolean,
    ) : GroupSetting

    data class Open(
        val value: Boolean,
    ) : GroupSetting

    /** `/img/groups/<hash>`, or `null` to take it away. */
    data class Picture(
        val path: String?,
    ) : GroupSetting

    data class Position(
        val position: UserPosition?,
    ) : GroupSetting
}
