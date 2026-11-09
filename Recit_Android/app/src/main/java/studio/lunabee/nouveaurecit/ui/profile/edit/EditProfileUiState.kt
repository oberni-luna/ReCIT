package studio.lunabee.nouveaurecit.ui.profile.edit

import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.data.user.ProfileDraft
import studio.lunabee.nouveaurecit.data.user.ProfileSaveFailure

/** Everything « Modifier le profil » draws, in one immutable value. */
data class EditProfileUiState(
    /** The form, once my user is read. Taken back from every save, so a retry sends only what is left. */
    val draft: ProfileDraft? = null,
    /** The picture on the server, shown while the draft has not touched it. */
    val savedPictureUrl: String? = null,
    val usernameCheck: FieldAvailability = FieldAvailability(FieldAvailability.Field.Username),
    /** What the last « Enregistrer » could not send. `null` until something is refused. */
    val failure: ProfileSaveFailure? = null,
    val isSaving: Boolean = false,
    /** Set once everything landed: the screen closes. */
    val isSaved: Boolean = false,
    /** The position's page, over the form. */
    val isPlacingPosition: Boolean = false,
) {
    val canSave: Boolean get() = draft?.canSave(usernameCheck) == true && !isSaving

    /** What the live check says about the name typed — nothing about the account's own name. */
    val usernameFailure: AuthFailure? get() = usernameCheck.failure?.takeIf { draft?.usernameNeedsCheck == true }
}
