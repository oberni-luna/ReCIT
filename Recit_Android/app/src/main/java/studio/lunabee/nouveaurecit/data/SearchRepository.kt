package studio.lunabee.nouveaurecit.data

import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.ImageUrl
import studio.lunabee.nouveaurecit.network.dto.SearchResultsDto

/** One remote search hit — `Model/SearchResult/SearchResult.swift`. */
data class SearchResult(
    val id: String,
    val type: Type,
    val uri: String,
    val label: String,
    val description: String?,
    val image: String?,
    val score: Double,
) {
    enum class Type(val raw: String) {
        Works("works"),
        Humans("humans"),
        ;

        companion object {
            fun from(raw: String): Type? = entries.firstOrNull { it.raw == raw }
        }
    }
}

/** `SearchModel`: `/api/search` for works and humans. Search never returns editions. */
class SearchRepository(private val api: ApiService) {
    suspend fun search(query: String, types: Set<SearchResult.Type> = SearchResult.Type.entries.toSet(), limit: Int = 15): List<SearchResult> {
        val trimmed: String = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        val response: SearchResultsDto = api.get(
            "/api/search",
            "types" to types.joinToString("|") { it.raw },
            "search" to trimmed,
            "lang" to "fr",
            "limit" to "$limit",
            "offset" to "0",
            "exact" to "false",
        )
        return response.results
            .mapNotNull { dto ->
                val type: SearchResult.Type = SearchResult.Type.from(dto.type) ?: return@mapNotNull null
                SearchResult(dto.id, type, dto.uri, dto.label, dto.description, ImageUrl.absolute(dto.image), dto.score ?: 0.0)
            }
            .sortedByDescending { it.score }
    }
}
