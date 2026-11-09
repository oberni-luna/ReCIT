package studio.lunabee.nouveaurecit.data.inventory

import studio.lunabee.nouveaurecit.data.db.InventoryDao

/** Where the texts of a book are kept, for [InventoryItemTextWriter]: the store, or memory in the tests. */
interface InventoryItemTextStore {
    /** The text as stored, or `null` once the item has left the store. */
    suspend fun text(itemId: String, attribute: InventoryItemTextAttribute): String?

    suspend fun setText(itemId: String, attribute: InventoryItemTextAttribute, text: String)
}

/** The texts in `inventory_items`. */
class RoomInventoryItemTextStore(private val dao: InventoryDao) : InventoryItemTextStore {
    override suspend fun text(itemId: String, attribute: InventoryItemTextAttribute): String? =
        dao.get(itemId)?.let(attribute::read)

    override suspend fun setText(itemId: String, attribute: InventoryItemTextAttribute, text: String) = when (attribute) {
        InventoryItemTextAttribute.Details -> dao.setDetails(itemId, text)
        InventoryItemTextAttribute.Notes -> dao.setNotes(itemId, text)
    }
}
