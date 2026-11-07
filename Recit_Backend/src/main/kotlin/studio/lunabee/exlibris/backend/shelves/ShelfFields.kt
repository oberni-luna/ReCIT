package studio.lunabee.exlibris.backend.shelves

/** What an owner sets on an étagère: inventaire.io's `updatable` shelf attributes. */
data class ShelfFields(
    val name: String,
    val description: String,
    val visibility: List<String>,
    val color: String?,
)
