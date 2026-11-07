package studio.lunabee.exlibris.backend.lists

/** inventaire.io's listing types, each with the entity types it holds (`entityTypesByListingType`). */
enum class ListType(
    val storedName: String,
    val entityTypes: Set<String>,
) {
    WORK("work", setOf("work", "serie")),
    AUTHOR("author", setOf("human")),
    PUBLISHER("publisher", setOf("publisher")),
    ;

    companion object {
        fun from(storedName: String): ListType? = entries.firstOrNull { it.storedName == storedName }
    }
}
