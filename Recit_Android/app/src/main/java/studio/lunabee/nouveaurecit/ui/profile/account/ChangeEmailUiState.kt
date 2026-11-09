package studio.lunabee.nouveaurecit.ui.profile.account

import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability

/** Everything « Adresse e-mail » draws, in one immutable value. */
data class ChangeEmailUiState(
    /** The address in use, as the account's settings hold it. */
    val current: String? = null,
    val email: String = "",
    /** The new address, checked while it is typed as at sign-up — and set from the server's refusal on save. */
    val check: FieldAvailability = FieldAvailability(FieldAvailability.Field.Email),
    val isSaving: Boolean = false,
    /** Set once the server has taken the address: the screen says where the link went, and closes. */
    val savedAddress: String? = null,
) {
    val typed: String get() = email.trim()

    val canSave: Boolean get() = "@" in typed && !typed.equals(current, ignoreCase = true) && !check.isRefused && !isSaving

    /** Why the address typed cannot be used: taken, or not an address. */
    val failure: AuthFailure? get() = check.failure
}
