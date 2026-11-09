package studio.lunabee.nouveaurecit.ui.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.ListRepository
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.lists.CoverFlowSelection
import studio.lunabee.nouveaurecit.data.lists.ListArrivalFocus
import studio.lunabee.nouveaurecit.data.lists.ListMoveDestination
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
 *
 * **Opened from a book screen** on [focusUri], the list arrives on that book ([ListArrivalFocus]): the screen
 * plays the arrival's phases, this keeps them — so a rotation does not play it again. With the system's
 * animations off ([reducesMotion]), the selection jumps onto the book before the covers first show.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class EntityListViewModel(
    private val listId: String,
    focusUri: String?,
    private val reducesMotion: Boolean,
    private val lists: ListRepository,
    private val entities: EntityRepository,
    myUserId: StateFlow<String?>,
) : ViewModel() {
    /** [isLoaded] is false until Room has answered once, so "not read yet" is not "gone". */
    data class State(
        val isLoaded: Boolean = false,
        val list: EntityListEntity? = null,
        val rows: List<ListElementRowModel> = emptyList(),
        /** How many elements the list holds, those whose work or author has not landed yet included: the first tab's count. */
        val elementCount: Int = 0,
        val selectedUri: String? = null,
        /** Where « Déplacer dans une autre liste » can take the selected element; empty, the row is hidden. */
        val destinations: List<ListMoveDestination> = emptyList(),
        val isMoving: Boolean = false,
        /**
         * Someone else's list, opened from their profile: nothing writes to it. Derived from the list's
         * creator rather than passed in — a list cannot lie about whose it is.
         */
        val isReadOnly: Boolean = false,
    ) {
        val selectedRow: ListElementRowModel? get() = rows.firstOrNull { it.uri == selectedUri }
    }

    private data class Content(
        val isLoaded: Boolean = false,
        val list: EntityListEntity? = null,
        val rows: List<ListElementRowModel> = emptyList(),
        val elementCount: Int = 0,
    )

    private val requested: MutableSet<String> = mutableSetOf()

    private val content: StateFlow<Content> = lists.observeList(listId)
        .flatMapLatest { entry -> rowsOf(entry).map { rows -> Content(isLoaded = true, list = entry?.list, rows = rows, elementCount = entry?.elements?.size ?: 0) } }
        .stateIn(viewModelScope, SharingStarted.Eagerly, Content())

    private val selection: MutableStateFlow<CoverFlowSelection.Result> = MutableStateFlow(CoverFlowSelection.Result(null, null))

    /** The uris of the rows the selection was last worked out against. */
    private var shownUris: List<String> = emptyList()

    private val isMoving: MutableStateFlow<Boolean> = MutableStateFlow(false)

    private val _arrival: MutableStateFlow<ListArrivalFocus> = MutableStateFlow(ListArrivalFocus.on(focusUri))
    val arrival: StateFlow<ListArrivalFocus> = _arrival.asStateFlow()

    val state: StateFlow<State> = combine(content, selection, lists.observeMyLists(), isMoving, myUserId) { current, selected, all, moving, myId ->
        val list: EntityListEntity? = current.list
        val uri: String? = selected.selected
        val isReadOnly: Boolean = list != null && !list.isCreatedByMe(myId)
        State(
            isLoaded = current.isLoaded,
            list = list,
            rows = current.rows,
            elementCount = current.elementCount,
            selectedUri = uri,
            destinations = if (list == null || uri == null || isReadOnly) {
                emptyList()
            } else {
                ListMoveDestination.destinations(
                    uri = uri,
                    currentListId = list.id,
                    type = list.type,
                    candidates = all.map { entry -> ListMoveDestination.Candidate(entry.list.id, entry.list.name, entry.list.type, entry.elements.map { it.uri }.toSet()) },
                )
            },
            isMoving = moving,
            isReadOnly = isReadOnly,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, State())

    init {
        viewModelScope.launch {
            content.map { current -> current.rows.map { it.uri } }.distinctUntilChanged().collect { uris ->
                val selected: String? = selection.value.selected
                val arrival: ListArrivalFocus = _arrival.value.start(uris, selected, reducesMotion)
                val jump: String? = arrival.jumpUri.takeIf { arrival != _arrival.value }
                _arrival.value = arrival
                setSelection(CoverFlowSelection.next(shownUris, uris, selected, jump ?: selection.value.requested))
                shownUris = uris
            }
        }
    }

    /** The cover facing the reader, as the strip settles on it. */
    fun select(uri: String) {
        if (uri in shownUris) setSelection(selection.value.copy(selected = uri))
    }

    /** Selects [uri] as soon as the list holds it — at once when it already does. */
    fun requestSelection(uri: String) {
        setSelection(CoverFlowSelection.next(shownUris, shownUris, selection.value.selected, uri))
    }

    /** The arrival's move is over: the halo lights if the selection stands on the book. */
    fun landArrival() {
        _arrival.update { it.land(selection.value.selected) }
    }

    /** The halo has faded. */
    fun endArrivalHighlight() {
        _arrival.update(ListArrivalFocus::endHighlight)
    }

    /** What the scanner or the search chose: added optimistically, the list landing on the first of it at once. */
    fun add(uris: List<String>) {
        val first: String = uris.firstOrNull() ?: return
        requestSelection(first)
        viewModelScope.launch { lists.addEntities(listId, uris) }
    }

    /**
     * « Déplacer dans une autre liste »: server-first. Returns whether it went through; [onError] says why
     * not. The element leaves the cover flow once the server has answered.
     */
    suspend fun move(row: ListElementRowModel, destination: ListMoveDestination, onError: (Throwable) -> Unit): Boolean {
        if (isMoving.value) return false
        isMoving.value = true
        return try {
            lists.moveElement(uri = row.uri, comment = row.comment, sourceId = listId, destinationId = destination.id)
            true
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            onError(error)
            false
        } finally {
            isMoving.value = false
        }
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

    /** Every selection change goes through here: one made elsewhere than the book puts the halo out. */
    private fun setSelection(result: CoverFlowSelection.Result) {
        selection.value = result
        _arrival.update { it.select(result.selected) }
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
