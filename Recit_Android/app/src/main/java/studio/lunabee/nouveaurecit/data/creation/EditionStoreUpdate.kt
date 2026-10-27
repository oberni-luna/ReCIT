package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.data.db.EditionEntity

/**
 * `EntityCreationModel.apply(_:since:to:)` (iOS feature 0049): what a save writes into the local edition,
 * so the book screen shows it at once. Pure, so the rule is tested without Room.
 *
 * After the server answered, never before: the store is a cache of inventaire.io, and this change is not
 * optimistic. Written directly rather than read back, because a read straight after a write can be served
 * from a cache the write has not reached. Only what moved: the local image may come from somewhere other
 * than `invp:P2`, and a cover nobody touched must not be cleared for having no hash.
 */
object EditionStoreUpdate {
    /** [existing] with what moved between [before] and [after], or `null` when nothing did. */
    fun edition(existing: EditionEntity, after: EditionClaims, before: EditionClaims): EditionEntity? {
        if (after == before) return null
        var updated: EditionEntity = existing
        if (after.title != before.title && after.title.isNotEmpty()) updated = updated.copy(title = after.title)
        if (after.subtitle != before.subtitle) updated = updated.copy(subtitle = after.subtitle)
        if (after.coverHash != before.coverHash) updated = updated.copy(image = after.coverUrl)
        val pages: ClaimLiteral? = after.properties.literal(EditionProperty.NumberOfPages)
        if (pages != before.properties.literal(EditionProperty.NumberOfPages)) {
            updated = updated.copy(numberOfPages = (pages as? ClaimLiteral.Integer)?.value)
        }
        return updated.takeIf { it != existing }
    }
}
