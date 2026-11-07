package studio.lunabee.exlibris.backend.lists

/**
 * What `by-creators` is asked beyond whose lists: inventaire.io's page ([limit] lists from [offset], the newest
 * first), its group [context], `with-elements` and the extra [attributes]. [lang] picks the covers of `images`.
 */
data class ListsPageRequest(
    val limit: Int = DEFAULT_LIMIT,
    val offset: Int = 0,
    val context: String? = null,
    val withElements: Boolean = false,
    val attributes: Set<String> = emptySet(),
    val lang: String = DEFAULT_LANG,
) {
    companion object {
        const val DEFAULT_LIMIT: Int = 100
        const val DEFAULT_LANG: String = "en"
    }
}
