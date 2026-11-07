package studio.lunabee.exlibris.backend.search

import kotlinx.serialization.Serializable

@Serializable
data class SearchResults(
    val results: List<SearchResult>,
)
