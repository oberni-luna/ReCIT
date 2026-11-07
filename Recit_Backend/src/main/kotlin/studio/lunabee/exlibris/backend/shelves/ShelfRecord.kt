package studio.lunabee.exlibris.backend.shelves

import studio.lunabee.exlibris.backend.db.DocumentId

/** A `shelves` row. */
data class ShelfRecord(
    val id: String,
    val version: Int,
    val owner: String,
    val name: String,
    val description: String,
    val visibility: List<String>,
    val color: String?,
    val created: Long,
    val updated: Long?,
) {
    /** As [viewerId] reads it: `visibility` stripped for anyone but the owner; [items] when they were asked for. */
    fun document(
        viewerId: String?,
        items: List<String>? = null,
    ): ShelfDocument =
        ShelfDocument(
            id = id,
            rev = DocumentId.revision(id, version),
            name = name,
            description = description,
            visibility = visibility.takeIf { owner == viewerId },
            owner = owner,
            color = color,
            created = created,
            updated = updated,
            items = items,
        )
}
