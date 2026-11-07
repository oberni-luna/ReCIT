package studio.lunabee.exlibris.backend.users

/** One `PUT /api/user`, read and checked for its shape: what [UsersRepository.apply] writes. */
sealed interface ProfileUpdate {
    /** Whether writing it would change [user]; inventaire.io refuses one that would not. */
    fun changes(user: UserRecord): Boolean

    data class Username(
        val value: String,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = value != user.username
    }

    data class Email(
        val value: String,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = value != user.email
    }

    data class Language(
        val value: String,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = value != user.language
    }

    data class Bio(
        val value: String,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = value != user.bio
    }

    /** `null` takes the picture away. */
    data class Picture(
        val path: String?,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = path != user.picture
    }

    /** `null` takes the position away. */
    data class Position(
        val position: UserPosition?,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = position != user.position
    }

    data class Fediversable(
        val value: Boolean,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = value != user.fediversable
    }

    data class SummaryPeriodicity(
        val days: Int,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = days != user.summaryPeriodicity
    }

    /** [name] is the switch's path under `settings`: `notifications.global`. */
    data class Setting(
        val name: String,
        val isEnabled: Boolean,
    ) : ProfileUpdate {
        override fun changes(user: UserRecord): Boolean = isEnabled != user.settings[name]
    }
}
