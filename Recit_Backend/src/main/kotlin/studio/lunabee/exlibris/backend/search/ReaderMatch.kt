package studio.lunabee.exlibris.backend.search

/** A reader whose username matches a search, and how closely: `pg_trgm`'s similarity, from 0 to 1. */
data class ReaderMatch(
    val id: String,
    val username: String,
    val bio: String?,
    val picture: String?,
    val similarity: Double,
)
