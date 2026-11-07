package studio.lunabee.exlibris.backend.auth

/** The pages an e-mailed link opens in a browser ([accountPage]). */
sealed interface AccountPage {
    data object EmailConfirmed : AccountPage

    data object ConfirmationLinkInvalid : AccountPage

    /** « Nouveau mot de passe », with what was wrong with the last answer, if anything. */
    data class ResetForm(
        val token: String,
        val problem: PasswordReset?,
    ) : AccountPage

    data object PasswordChanged : AccountPage

    data object ResetLinkInvalid : AccountPage
}
