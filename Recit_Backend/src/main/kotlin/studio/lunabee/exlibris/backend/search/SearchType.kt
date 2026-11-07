package studio.lunabee.exlibris.backend.search

/**
 * inventaire.io's `indexedTypes`, the values `types` accepts, split as #62 decision 10 splits them: the social
 * ones searched here, the entity ones relayed to inventaire.io (#76). `groups` is #72's; `shelves` and `lists`
 * the apps never search.
 */
enum class SearchType(
    val parameter: String,
    val isSocial: Boolean,
) {
    WORKS("works", isSocial = false),
    HUMANS("humans", isSocial = false),
    GENRES("genres", isSocial = false),
    PUBLISHERS("publishers", isSocial = false),
    SERIES("series", isSocial = false),
    COLLECTIONS("collections", isSocial = false),
    MOVEMENTS("movements", isSocial = false),
    LANGUAGES("languages", isSocial = false),
    USERS("users", isSocial = true),
    GROUPS("groups", isSocial = true),
    SHELVES("shelves", isSocial = true),
    LISTS("lists", isSocial = true),
    ;

    companion object {
        fun of(parameter: String): SearchType? = entries.firstOrNull { it.parameter == parameter }
    }
}
