package studio.lunabee.exlibris.backend.items

/** A book as `inventory-view` files it: by its owner, and by the works of its entity. */
data class ViewItem(
    val id: String,
    val owner: String,
    val entity: String,
)
