package studio.lunabee.exlibris.backend.users

/** A `users` row as its owner may read it: no password hash. A `null` is an attribute never set. */
data class UserRecord(
    val id: String,
    val version: Int,
    val username: String,
    val email: String,
    val language: String,
    val isEmailValidated: Boolean,
    val created: Long,
    val bio: String? = null,
    val picture: String? = null,
    val position: UserPosition? = null,
    val fediversable: Boolean? = null,
    val summaryPeriodicity: Int? = null,
    /** The switches of `settings` ever set, by their path under it: `notifications.global`. */
    val settings: Map<String, Boolean> = emptyMap(),
)
