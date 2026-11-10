package studio.lunabee.nouveaurecit.data.groups

import java.io.Serializable

/**
 * `GroupPictureEdit`: what « Réglages du groupe » has done to the group's photo since it opened.
 * Nothing leaves the phone before « Enregistrer », so a photo picked then replaced, or the sheet
 * closed, costs nothing.
 *
 * [Serializable] so that a photo picked survives a rotation, as the sheet's texts do.
 */
sealed interface GroupPictureEdit : Serializable {
    data object Unchanged : GroupPictureEdit

    /** A photo picked and reduced, waiting in the cache at [path] for « Enregistrer ». */
    data class Replaced(val path: String) : GroupPictureEdit

    data object Removed : GroupPictureEdit

    /** Whether « Enregistrer » has a photo to write: taking away a photo the group does not have is nothing. */
    fun isChange(from: String?): Boolean = when (this) {
        Unchanged -> false
        is Replaced -> true
        Removed -> from != null
    }
}
