package studio.lunabee.nouveaurecit.data.sorting

import java.util.UUID

/**
 * `SortDraftID`: the client id an étagère drafted on the sorting surface carries until it is created
 * for real.
 *
 * Prefixed, exactly as [studio.lunabee.nouveaurecit.data.OptimisticRunner] prefixes a placeholder,
 * and for the same reason: the write plan decides what to create by asking whether a section is a
 * draft, and a bare UUID sitting where a CouchDB `_id` is expected is a mistake nothing would catch.
 */
object SortDraftId {
    const val PREFIX: String = "draft:"

    fun make(): String = "$PREFIX${UUID.randomUUID().toString().uppercase()}"

    fun isDraft(id: String): Boolean = id.startsWith(PREFIX)
}
