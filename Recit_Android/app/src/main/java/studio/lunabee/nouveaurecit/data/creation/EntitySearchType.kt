package studio.lunabee.nouveaurecit.data.creation

/**
 * The `/api/search` types the pickers of « Modifier l'édition » and « Nouveau livre » search
 * (`SearchResultType` on iOS, restricted to what an edition names). Kept apart from
 * `SearchResult.Type`, which is the Recherche tab's — works and people, each with a screen to open.
 */
enum class EntitySearchType(val raw: String) {
    Works("works"),
    Humans("humans"),
    Publishers("publishers"),
    Collections("collections"),
    Languages("languages"),
}

/** One entity a picker's search found: what the row draws, and the uri a claim names it by. */
data class EntitySearchHit(
    val uri: String,
    val label: String,
    /** What tells it apart from a namesake. */
    val description: String? = null,
    /** Absolute, ready for Coil. */
    val image: String? = null,
)
