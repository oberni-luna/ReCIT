package studio.lunabee.exlibris.backend.search

/** A searchable group whose name matches a search, and how closely: `pg_trgm`'s similarity, from 0 to 1. */
data class GroupMatch(
    val id: String,
    val name: String,
    val description: String,
    val picture: String?,
    val similarity: Double,
)
