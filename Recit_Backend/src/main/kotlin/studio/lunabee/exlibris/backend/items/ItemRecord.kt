package studio.lunabee.exlibris.backend.items

import studio.lunabee.exlibris.backend.db.DocumentId

/** An `items` row, with the étagères it is on in the order it was filed on them. */
data class ItemRecord(
    val id: String,
    val version: Int,
    val owner: String,
    val entity: String,
    val transaction: TransactionMode,
    val visibility: List<String>,
    val details: String?,
    val notes: String?,
    val previousEntities: List<String>?,
    val created: Long,
    val updated: Long?,
    val shelves: List<String>,
) {
    /** As [viewerId] reads it: `visibility` and `notes` stripped for anyone but the owner. */
    fun document(
        viewerId: String?,
        snapshot: ItemSnapshot?,
        busy: Boolean?,
    ): ItemDocument {
        val isOwner: Boolean = owner == viewerId
        return ItemDocument(
            id = id,
            rev = DocumentId.revision(id, version),
            entity = entity,
            transaction = transaction.storedName,
            visibility = visibility.takeIf { isOwner },
            details = details,
            notes = notes.takeIf { isOwner },
            shelves = shelves,
            owner = owner,
            created = created,
            updated = updated,
            previousEntities = previousEntities,
            busy = busy,
            snapshot = snapshot,
        )
    }
}
