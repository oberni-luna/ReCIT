package studio.lunabee.exlibris.backend.shelves

import kotlinx.serialization.Serializable

/** `by-ids`, `by-owners`, `add-items`, `remove-items`: the étagères by id. */
@Serializable
data class ShelvesById(
    val shelves: Map<String, ShelfDocument>,
)
