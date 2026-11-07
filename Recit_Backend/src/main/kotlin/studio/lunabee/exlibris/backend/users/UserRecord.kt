package studio.lunabee.exlibris.backend.users

/** A `users` row as its owner may read it: no password hash. */
data class UserRecord(
    val id: String,
    val version: Int,
    val username: String,
    val email: String,
    val language: String,
    val isEmailValidated: Boolean,
    val created: Long,
)
