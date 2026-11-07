package studio.lunabee.exlibris.backend.search

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/**
 * `GET /api/search`, refused as inventaire.io refuses it — an unknown type, social and entity types mixed, no
 * `search` — and answered for `users` (#71) and `groups` (#72), alone or together, the closest first. The entity
 * types (#76), `shelves` and `lists` answer `501` until their tasks land.
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

                !searched.containsAll(types) -> {
                    ApiException(HttpStatusCode.NotImplemented, "not implemented: types=$typesParameter")
                }

                else -> {
                    null
                }
            }
        refusal?.let { throw it }
        val term: String = requireNotNull(search).trim()
        val results: List<SearchResult> =
            types.flatMap { type -> if (type == SearchType.USERS) readers(term, limit) else groups(term, limit) }
        return SearchResults(results.sortedByDescending { it.score }.take(limit))
    }

    private suspend fun readers(
        term: String,
        limit: Int,
    ): List<SearchResult> =
        repository.readers(term, limit).map { reader ->
            SearchResult(
                id = reader.id,
                type = SearchType.USERS.parameter,
                label = reader.username,
                description = reader.bio?.takeIf { it.isNotEmpty() },
                image = reader.picture,
                score = reader.similarity,
            )
        }

    private suspend fun groups(
        term: String,
        limit: Int,
    ): List<SearchResult> =
        repository.groups(term, limit).map { group ->
            SearchResult(
                id = group.id,
                type = SearchType.GROUPS.parameter,
                label = group.name,
                description = group.description.takeIf { it.isNotEmpty() },
                image = group.picture,
                score = group.similarity,
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

        /** The types this backend searches itself. */
        val searched: Set<SearchType> = setOf(SearchType.USERS, SearchType.GROUPS)
    }
}
