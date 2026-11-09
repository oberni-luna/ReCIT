package studio.lunabee.nouveaurecit.data.user

import studio.lunabee.nouveaurecit.network.NetworkError

/**
 * `ProfileSaveFailure` (iOS feature 0055): « Enregistrer » stopped part of the way. A profile is written one
 * attribute per request, so there is no saving it all or nothing: what went through before the refusal
 * stays ([landed]), and [refused] says which one was refused — the next « Enregistrer » sends it and
 * whatever came after.
 */
class ProfileSaveFailure(
    val refused: ProfileChange.Kind,
    val landed: List<ProfileChange>,
    cause: Throwable,
) : Exception(cause) {
    /**
     * The name went to someone else between the live check and the save. The server says so in prose
     * (« this username is already used »), the same token `FieldAvailability` reads.
     */
    val isUsernameTaken: Boolean
        get() {
            val error: Throwable? = cause
            return refused == ProfileChange.Kind.Username && error is NetworkError.BadStatus && error.code == 400 && "already used" in error.body
        }
}
