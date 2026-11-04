package studio.lunabee.nouveaurecit.ui.lists

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.db.ListWithElements

/**
 * The rows of the Lists tab, for any set of lists — mine in the tab, a reader's on their profile: each
 * list with the covers of its first elements, read from Room, and fetched once for the life of [scope]
 * when the store lacks them (`ListCoverFan.fetchMissing`).
 */
@OptIn(ExperimentalCoroutinesApi::class)
class ListRowFeed(private val entities: EntityRepository, private val scope: CoroutineScope) {
    private val requested: MutableSet<String> = mutableSetOf()

    fun rows(lists: Flow<List<ListWithElements>>, query: Flow<String>): Flow<List<ListRowModel>> {
        val fetching: Flow<List<ListWithElements>> = lists.onEach(::fetchMissingCovers)
        val images: Flow<Map<String, String?>> = fetching
            .map(ListsPresentation::coverUris)
            .distinctUntilChanged()
            .flatMapLatest { (workUris, authorUris) ->
                combine(
                    entities.entities.observeWorksWithAuthors(workUris),
                    entities.entities.observeAuthors(authorUris),
                ) { works, authors ->
                    works.associate { it.work.uri to it.work.image } + authors.associate { it.uri to it.image }
                }
            }
        return combine(fetching, query, images, ListsPresentation::rows)
    }

    private fun fetchMissingCovers(lists: List<ListWithElements>) {
        val (workUris, authorUris) = ListsPresentation.coverUris(lists)
        val works: List<String> = workUris.filter { requested.add(it) }
        val authors: List<String> = authorUris.filter { requested.add(it) }
        if (works.isNotEmpty()) scope.launch { runCatching { entities.getOrFetchWorks(works) } }
        if (authors.isNotEmpty()) scope.launch { runCatching { entities.getOrFetchAuthors(authors) } }
    }
}
