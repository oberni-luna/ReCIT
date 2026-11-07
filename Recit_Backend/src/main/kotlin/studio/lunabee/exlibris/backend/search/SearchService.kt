package studio.lunabee.exlibris.backend.search

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/**
 * `GET /api/search`, refused as inventaire.io refuses it — an unknown type, social and entity types mixed, no
 * `search` — and answered for `types=users` alone (#71). Groups (#72) and the entity types (#76) answer
 * `501` until their tasks land.
 */
class SearchService(
    private val repository: SearchRepository,
) {
    suspend fun search(
        typesParameter: String,
        search: String?,
        limitParameter: String?,
    ): SearchResults {
        val types: Set<SearchType> = types(typesParameter)
        val limit: Int = limitParameter?.let(::limit) ?: DEFAULT_LIMIT
        val refusal: ApiException? =
            when {
                types.any { it.isSocial } && types.any { !it.isSocial } -> {
                    ApiException(HttpStatusCode.BadRequest, "can not have both social and entity types")
                }

                search.isNullOrBlank() -> {
                    ApiException.missingParameter(ParameterPlace.QUERY, "search or claim")
                }

                types != setOf(SearchType.USERS) -> {
                    ApiException(HttpStatusCode.NotImplemented, "not implemented: types=$typesParameter")
                }

                else -> {
                    null
                }
            }
        refusal?.let { throw it }
        return SearchResults(
            repository.readers(requireNotNull(search).trim(), limit).map { reader ->
                SearchResult(
                    id = reader.id,
                    type = SearchType.USERS.parameter,
                    label = reader.username,
                    description = reader.bio?.takeIf { it.isNotEmpty() },
                    image = reader.picture,
                    score = reader.similarity,
                )
            },
        )
    }

    private fun types(parameter: String): Set<SearchType> =
        parameter
            .split('|')
            .map { name ->
                SearchType.of(name) ?: throw ApiException(
                    HttpStatusCode.BadRequest,
                    "invalid types: $name (possible values: ${SearchType.entries.joinToString { it.parameter }})",
                )
            }.toSet()

    /** inventaire.io's `limit`: an integer, 10 by default, at most 100. */
    private fun limit(parameter: String): Int =
        parameter.toIntOrNull()?.takeIf { it > 0 }?.coerceAtMost(MAX_LIMIT)
            ?: throw ApiException.invalidParameter("limit", parameter)

    private companion object {
        const val DEFAULT_LIMIT: Int = 10
        const val MAX_LIMIT: Int = 100
    }
}
