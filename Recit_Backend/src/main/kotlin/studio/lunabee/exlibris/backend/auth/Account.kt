package studio.lunabee.exlibris.backend.auth

/** An account as signing in sees it. */
data class Account(
    val id: String,
    val username: String,
    val email: String,
    val passwordHash: String,
    val language: String,
    val isEmailValidated: Boolean,
)
