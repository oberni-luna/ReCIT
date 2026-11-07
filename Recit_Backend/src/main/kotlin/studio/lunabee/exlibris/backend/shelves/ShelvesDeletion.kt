package studio.lunabee.exlibris.backend.shelves

import kotlinx.serialization.Serializable
import studio.lunabee.exlibris.backend.items.ItemDocument

/** `delete`: the étagères removed, with the ids of their books, and with `with-items` the books deleted with them. */
@Serializable
data class ShelvesDeletion(
    val ok: Boolean = true,
    val shelves: List<ShelfDocument>,
    val items: List<ItemDocument>? = null,
)
