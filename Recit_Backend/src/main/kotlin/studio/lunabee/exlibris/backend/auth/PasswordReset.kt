package studio.lunabee.exlibris.backend.auth

/** What the « Nouveau mot de passe » form's answer was. */
enum class PasswordReset {
    DONE,
    MISMATCH,
    INVALID_PASSWORD,
    INVALID_LINK,
}
