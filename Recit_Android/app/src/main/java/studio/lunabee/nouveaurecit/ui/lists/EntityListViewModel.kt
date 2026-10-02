package studio.lunabee.nouveaurecit.ui.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.ListRepository
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.model.EntityListType

/**
 * `EntityListDetail`'s state: the list from Room, its elements in `ordinal` order joined to the works
 * or authors they name — an element whose entity the store does not hold yet is fetched once, and
 * shows when it lands, as the `@Query` rows of iOS do.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class EntityListViewModel(
    private val listId: String,
    private val lists: ListRepository,
    private val entities: EntityRepository,
) : ViewModel() {
    /** [isLoaded] is false until Room has answered once, so "not read yet" is not "gone". */
    data class State(
        val isLoaded: Boolean = false,
        val list: EntityListEntity? = null,
        val rows: List<ListElementRowModel> = emptyList(),
    )

    private val requested: MutableSet<String> = mutableSetOf()

    val state: StateFlow<State> = lists.observeList(listId)
        .flatMapLatest { entry -> rowsOf(entry).map { rows -> State(isLoaded = true, list = entry?.list, rows = rows) } }
        .stateIn(viewModelScope, SharingStarted.Eagerly, State())

    /** Server-first. Returns whether it went through; [onError] says why not. */
    suspend fun remove(uri: String, onError: (Throwable) -> Unit): Boolean = try {
        lists.removeEntities(listId, listOf(uri))
        true
    } catch (error: Exception) {
        onError(error)
        false
    }

    private fun rowsOf(entry: ListWithElements?): Flow<List<ListElementRowModel>> {
        if (entry == null) return flowOf(emptyList())
        val elements: List<EntityListItemEntity> = ListsPresentation.orderedElements(entry.elements)
        val uris: List<String> = elements.map { it.uri }
        fetchMissing(entry.list.type, uris)
        return when (entry.list.type) {
            EntityListType.Work -> entities.entities.observeWorksWithAuthors(uris).map { works ->
                val byUri: Map<String, ListElementRowModel> = works.associate { it.work.uri to ListElementRowModel(it.work.uri, it.work.title, it.work.subtitle, it.work.image, "") }
                elements.mapNotNull { element -> byUri[element.uri]?.copy(comment = element.comment) }
            }
            EntityListType.Author -> entities.entities.observeAuthors(uris).map { authors ->
                val byUri: Map<String, ListElementRowModel> = authors.associate { it.uri to ListElementRowModel(it.uri, it.name, it.subtitle, it.image, "") }
                elements.mapNotNull { element -> byUri[element.uri]?.copy(comment = element.comment) }
            }
            EntityListType.Publisher -> flowOf(emptyList())
        }.distinctUntilChanged()
    }

    private fun fetchMissing(type: EntityListType, uris: List<String>) {
        val missing: List<String> = uris.filter { requested.add(it) }
        if (missing.isEmpty()) return
        viewModelScope.launch {
            runCatching {
                when (type) {
                    EntityListType.Work -> entities.getOrFetchWorks(missing)
                    EntityListType.Author -> entities.getOrFetchAuthors(missing)
                    EntityListType.Publisher -> Unit
                }
            }
        }
    }
}
