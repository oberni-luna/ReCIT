package studio.lunabee.exlibris.backend.lists

/** What a creator changes on a list: inventaire.io's `updatable` listing attributes. */
data class ListFields(
    val name: String,
    val description: String,
    val visibility: List<String>,
)
