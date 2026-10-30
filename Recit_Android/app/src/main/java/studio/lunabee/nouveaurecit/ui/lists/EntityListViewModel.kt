package studio.lunabee.nouveaurecit.ui.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
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
import studio.lunabee.nouveaurecit.data.lists.CoverFlowSelection
import studio.lunabee.nouveaurecit.data.model.EntityListType

/**
 * `EntityListDetail` and `ListCoverFlowScreen`'s state: the list from Room, its elements in `ordinal`
 * order joined to the works or authors they name — an element whose entity the store does not hold yet
 * is fetched once, and shows when it lands, as the `@Query` rows of iOS do — and the element facing the
 * reader in the cover flow.
 *
 * **The selection survives the list changing under it** ([CoverFlowSelection]): it is a uri, so an
 * element whose optimistic id is replaced by the server's stays selected; an element removed hands the
 * selection to the one that took its place; a uri asked for by an add is selected as soon as the list
 * holds it.
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
        val selectedUri: String? = null,
    ) {
        val selectedRow: ListElementRowModel? get() = rows.firstOrNull { it.uri == selectedUri }
    }

    private data class Content(
        val isLoaded: Boolean = false,
        val list: EntityListEntity? = null,
        val rows: List<ListElementRowModel> = emptyList(),
    )

    private val requested: MutableSet<String> = mutableSetOf()

    private val content: StateFlow<Content> = lists.observeList(listId)
        .flatMapLatest { entry -> rowsOf(entry).map { rows -> Content(isLoaded = true, list = entry?.list, rows = rows) } }
        .stateIn(viewModelScope, SharingStarted.Eagerly, Content())

    private val selection: MutableStateFlow<CoverFlowSelection.Result> = MutableStateFlow(CoverFlowSelection.Result(null, null))

    /** The uris of the rows the selection was last worked out against. */
    private var shownUris: List<String> = emptyList()

    val state: StateFlow<State> = combine(content, selection) { current, selected ->
        State(isLoaded = current.isLoaded, list = current.list, rows = current.rows, selectedUri = selected.selected)
    }.stateIn(viewModelScope, SharingStarted.Eagerly, State())

    init {
        viewModelScope.launch {
            content.map { current -> current.rows.map { it.uri } }.distinctUntilChanged().collect { uris ->
                selection.value = CoverFlowSelection.next(shownUris, uris, selection.value.selected, selection.value.requested)
                shownUris = uris
            }
        }
    }

    /** The cover facing the reader, as the strip settles on it. */
    fun select(uri: String) {
        if (uri in shownUris) selection.value = selection.value.copy(selected = uri)
    }

    /** Selects [uri] as soon as the list holds it — at once when it already does. */
    fun requestSelection(uri: String) {
        selection.value = CoverFlowSelection.next(shownUris, shownUris, selection.value.selected, uri)
    }

    /** Optimistic; written when the field is left. */
    fun updateComment(row: ListElementRowModel, comment: String) {
        viewModelScope.launch { lists.updateComment(row.elementId, comment) }
    }

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
                val byUri: Map<String, ListElementRowModel> = works.associate { entry ->
                    entry.work.uri to ListElementRowModel(
                        uri = entry.work.uri,
                        title = entry.work.title,
                        subtitle = entry.work.subtitle,
                        image = entry.work.image,
                        comment = "",
                        authors = entry.authors.map { it.name }.filter { it.isNotEmpty() }.joinToString(", ").ifEmpty { null },
                    )
                }
                elements.mapNotNull { element -> byUri[element.uri]?.with(element) }
            }
            EntityListType.Author -> entities.entities.observeAuthors(uris).map { authors ->
                val byUri: Map<String, ListElementRowModel> = authors.associate { it.uri to ListElementRowModel(it.uri, it.name, it.subtitle, it.image, "") }
                elements.mapNotNull { element -> byUri[element.uri]?.with(element) }
            }
            EntityListType.Publisher -> flowOf(emptyList())
        }.distinctUntilChanged()
    }

    private fun ListElementRowModel.with(element: EntityListItemEntity): ListElementRowModel =
        copy(comment = element.comment, elementId = element.id, created = element.created)

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
