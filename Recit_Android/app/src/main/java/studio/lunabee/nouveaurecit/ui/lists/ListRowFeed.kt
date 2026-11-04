package studio.lunabee.nouveaurecit.ui.lists

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.shareIn
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

    /** [lists] as rows, by name, collected once whatever the covers need. */
    fun rows(lists: Flow<List<ListWithElements>>): Flow<List<ListRowModel>> {
        val shared: SharedFlow<List<ListWithElements>> = lists.shareIn(scope, SharingStarted.WhileSubscribed(), replay = 1)
        return combine(shared, images(shared), ListsPresentation::rows)
    }

    /** The covers of [lists]' first elements, by entity uri, as Room holds them. */
    fun images(lists: Flow<List<ListWithElements>>): Flow<Map<String, String?>> = lists
        .onEach(::fetchMissingCovers)
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

    private fun fetchMissingCovers(lists: List<ListWithElements>) {
        val (workUris, authorUris) = ListsPresentation.coverUris(lists)
        val works: List<String> = workUris.filter { requested.add(it) }
        val authors: List<String> = authorUris.filter { requested.add(it) }
        if (works.isNotEmpty()) scope.launch { runCatching { entities.getOrFetchWorks(works) } }
        if (authors.isNotEmpty()) scope.launch { runCatching { entities.getOrFetchAuthors(authors) } }
    }
}
