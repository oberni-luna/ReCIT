package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.Serializable

/** `POST /api/items`: the book created, with its snapshot. */
@Serializable
data class CreatedItem(
    val item: ItemDocument,
)
