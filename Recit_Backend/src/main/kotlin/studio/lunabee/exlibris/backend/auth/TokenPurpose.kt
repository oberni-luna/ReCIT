package studio.lunabee.exlibris.backend.auth

import java.time.Duration

/** What an e-mailed link is for, as `user_tokens.purpose` stores it, and how long it opens. */
enum class TokenPurpose(
    val storedName: String,
    val lifetime: Duration,
) {
    EMAIL_CONFIRMATION("email_confirmation", Duration.ofDays(1)),
    PASSWORD_RESET("password_reset", Duration.ofHours(1)),
}
