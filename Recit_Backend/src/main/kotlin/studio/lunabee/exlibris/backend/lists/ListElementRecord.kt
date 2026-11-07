package studio.lunabee.exlibris.backend.lists

import studio.lunabee.exlibris.backend.db.DocumentId

/** A `list_elements` row. */
data class ListElementRecord(
    val id: String,
    val version: Int,
    val listId: String,
    val uri: String,
    val ordinal: String,
    val comment: String?,
    val previousUris: List<String>?,
    val created: Long,
    val updated: Long?,
) {
    fun document(): ListElementDocument =
        ListElementDocument(
            id = id,
            rev = DocumentId.revision(id, version),
            list = listId,
            uri = uri,
            ordinal = ordinal,
            created = created,
            updated = updated,
            comment = comment,
            previousUris = previousUris,
        )
}
