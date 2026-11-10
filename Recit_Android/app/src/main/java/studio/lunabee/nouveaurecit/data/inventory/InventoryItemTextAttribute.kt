package studio.lunabee.nouveaurecit.data.inventory

import studio.lunabee.nouveaurecit.data.db.InventoryItemEntity

/**
 * `InventoryItemTextAttribute`: a text the owner writes on a book, under the attribute name
 * `PUT /api/items/bulk-update` takes.
 */
enum class InventoryItemTextAttribute(val raw: String) {
    /** The Commentaire, seen by whoever can see the book. */
    Details("details"),

    /** The Note privée, seen by the owner alone. */
    Notes("notes"),
    ;

    fun read(item: InventoryItemEntity): String = when (this) {
        Details -> item.details
        Notes -> item.notes
    }
}
