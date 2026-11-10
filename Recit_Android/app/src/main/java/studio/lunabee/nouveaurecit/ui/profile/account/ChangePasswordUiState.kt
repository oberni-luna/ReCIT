package studio.lunabee.nouveaurecit.ui.profile.account

import studio.lunabee.nouveaurecit.data.user.PasswordChangeFailure

/** Everything « Mot de passe » draws, in one immutable value. */
data class ChangePasswordUiState(
    val current: String = "",
    val new: String = "",
    /** Why the last « Enregistrer » was refused; cleared as soon as the current password is typed again. */
    val failure: PasswordChangeFailure.Reason? = null,
    val isSaving: Boolean = false,
    /** Set once the server has taken the new password: the screen closes with a confirmation. */
    val isSaved: Boolean = false,
    val isRequestingReset: Boolean = false,
) {
    val canSave: Boolean get() = current.isNotEmpty() && new.length in LENGTH_RANGE && !isSaving

    private companion object {
        /** `BoundedString(8, 256)` in `server/models/validations/user.ts`. */
        val LENGTH_RANGE: IntRange = 8..256
    }
}
