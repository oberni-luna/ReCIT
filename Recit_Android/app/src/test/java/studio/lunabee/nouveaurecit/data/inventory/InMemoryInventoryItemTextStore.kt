package studio.lunabee.nouveaurecit.data.inventory

import java.util.concurrent.ConcurrentHashMap

/** `InventoryItemTextStore` in memory: each item's texts by attribute. */
class InMemoryInventoryItemTextStore : InventoryItemTextStore {
    private val texts: MutableMap<String, Map<InventoryItemTextAttribute, String>> = ConcurrentHashMap()

    fun put(itemId: String, details: String = "", notes: String = "") {
        texts[itemId] = mapOf(InventoryItemTextAttribute.Details to details, InventoryItemTextAttribute.Notes to notes)
    }

    override suspend fun text(itemId: String, attribute: InventoryItemTextAttribute): String? = texts[itemId]?.get(attribute)

    override suspend fun setText(itemId: String, attribute: InventoryItemTextAttribute, text: String) {
        texts.computeIfPresent(itemId) { _, current -> current + (attribute to text) }
    }
}
