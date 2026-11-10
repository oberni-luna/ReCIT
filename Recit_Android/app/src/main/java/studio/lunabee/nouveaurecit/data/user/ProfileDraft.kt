package studio.lunabee.nouveaurecit.data.user

import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.data.db.UserEntity
import kotlin.math.ceil
import kotlin.math.floor

/**
 * `ProfileDraft` (iOS feature 0055): « Modifier le profil » while it is being typed — what the form shows,
 * set against what the server last agreed to ([saved]). Pure, so that what gets sent is decided here, and
 * tested here.
 *
 * Only what changed is sent, because `PUT /api/user` answers `400 already up-to-date` to a value it
 * already has, and because every request costs a second ([RequestPacer]). The order is the one the form
 * reads in: picture, name, bio, position.
 */
data class ProfileDraft(
    val saved: Saved,
    val picture: Picture = Picture.Unchanged,
    val username: String = saved.username,
    val bio: String = saved.bio,
    val position: Coordinates? = saved.position,
) {
    /** What the server holds, as far as the form knows. */
    data class Saved(
        val username: String,
        val bio: String,
        val position: Coordinates?,
        /** Whether the account has a picture — the only case where removing one is a change rather than nothing. */
        val hasPicture: Boolean,
    )

    sealed interface Picture {
        data object Unchanged : Picture

        /** The path of the reduced JPEG chosen to replace it. */
        data class Replaced(val path: String) : Picture

        data object Removed : Picture
    }

    private val trimmedUsername: String get() = username.trim()

    private val trimmedBio: String get() = bio.trim()

    /** What « Enregistrer » sends, in the order it sends it. */
    val changes: List<ProfileChange>
        get() = buildList {
            when (picture) {
                Picture.Unchanged -> Unit
                is Picture.Replaced -> add(ProfileChange.Picture(picture.path))
                Picture.Removed -> if (saved.hasPicture) add(ProfileChange.Picture(null))
            }
            if (trimmedUsername != saved.username) add(ProfileChange.Username(trimmedUsername))
            if (trimmedBio != saved.bio) add(ProfileChange.Bio(trimmedBio))
            if (position != saved.position) add(ProfileChange.Position(position))
        }

    /**
     * Whether the name typed has to be asked about. Not when it is the account's own, nor when only its
     * case moved: the availability check would answer « taken » about the account itself, and the server
     * lets an account keep its own name in another case.
     */
    val usernameNeedsCheck: Boolean get() = !trimmedUsername.equals(saved.username, ignoreCase = true)

    val bioLength: Int get() = bio.length

    val isBioTooLong: Boolean get() = bioLength > BIO_LIMIT

    val isUsernameEmpty: Boolean get() = trimmedUsername.isEmpty()

    /** Something to send, and nothing the server is bound to refuse. */
    val isSaveable: Boolean get() = changes.isNotEmpty() && !isBioTooLong && !isUsernameEmpty

    /** Whether there is a picture to show — and so to offer to remove. */
    val showsPicture: Boolean
        get() = when (picture) {
            Picture.Unchanged -> saved.hasPicture
            is Picture.Replaced -> true
            Picture.Removed -> false
        }

    /** [isSaveable], and the name typed not refused by the live check — a name the account already has is never asked about. */
    fun canSave(usernameCheck: FieldAvailability): Boolean = isSaveable && (!usernameNeedsCheck || !usernameCheck.isRefused)

    /**
     * Places the position, rounded to two decimals — about a kilometre. A position is public on
     * inventaire.io, and it is meant to say which neighbourhood, not which door.
     */
    fun placed(at: Coordinates?): ProfileDraft = copy(position = at?.let(::rounded))

    /** Takes in what the server has accepted, so that the next « Enregistrer » after a partial failure sends only what is left. */
    fun markLanded(landed: List<ProfileChange>): ProfileDraft = landed.fold(this) { draft, change ->
        when (change) {
            is ProfileChange.Picture -> draft.copy(picture = Picture.Unchanged, saved = draft.saved.copy(hasPicture = change.path != null))
            is ProfileChange.Username -> draft.copy(saved = draft.saved.copy(username = change.value))
            is ProfileChange.Bio -> draft.copy(saved = draft.saved.copy(bio = change.value))
            is ProfileChange.Position -> draft.copy(saved = draft.saved.copy(position = change.coordinates))
        }
    }

    companion object {
        /** `BoundedString(0, 1000)` in `server/models/validations/user.ts`. */
        const val BIO_LIMIT: Int = 1_000

        fun of(user: UserEntity): ProfileDraft = ProfileDraft(
            Saved(
                username = user.username,
                bio = user.bio.orEmpty(),
                position = if (user.latitude != null && user.longitude != null) Coordinates(user.latitude, user.longitude) else null,
                hasPicture = user.avatarUrl != null,
            ),
        )

        fun rounded(coordinates: Coordinates): Coordinates =
            Coordinates(latitude = roundedToHundredths(coordinates.latitude), longitude = roundedToHundredths(coordinates.longitude))

        /** Half away from zero, as Swift's `rounded()`: the two apps place the same pin at the same point. */
        private fun roundedToHundredths(value: Double): Double {
            val scaled: Double = value * 100
            return (if (scaled >= 0) floor(scaled + 0.5) else ceil(scaled - 0.5)) / 100
        }
    }
}
