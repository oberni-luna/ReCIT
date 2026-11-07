package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.Serializable

/** `GET /api/items/by-ids`: the books the caller may see, the newest first, [total] before the page was cut. */
@Serializable
data class ItemsPage(
    val items: List<ItemDocument>,
    val total: Int,
    val offset: Int,
)
