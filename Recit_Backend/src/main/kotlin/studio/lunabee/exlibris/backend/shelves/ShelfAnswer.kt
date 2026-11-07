package studio.lunabee.exlibris.backend.shelves

import kotlinx.serialization.Serializable

/** `create` and `update`: the étagère as it now is. */
@Serializable
data class ShelfAnswer(
    val shelf: ShelfDocument,
)
