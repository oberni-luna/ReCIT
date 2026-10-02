package studio.lunabee.nouveaurecit.ui.book

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
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
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.book.WorkEditionResolver
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.EditionWithWorks
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor

/** What the book screen shows: the [BookPhase] decides the frame, the rest fills it. */
data class BookUiState(
    val phase: BookPhase = BookPhase.Loading,
    val edition: EditionEntity? = null,
    val works: List<WorkEntity> = emptyList(),
    val authors: List<AuthorEntity> = emptyList(),
    val worksWithOtherEditions: List<WorkEntity> = emptyList(),
    val myItem: ItemRow? = null,
    val othersItems: List<ItemRow> = emptyList(),
    val summary: SummaryState = SummaryState.Loading,
    val myShelves: List<MembershipEntry> = emptyList(),
    val myLists: List<MembershipEntry> = emptyList(),
) {
    /** Listes hold works: an edition behind several works offers no list menu at all. */
    val singleWorkUri: String? get() = works.singleOrNull()?.uri
}

/** `BookViewModel.ViewState`. */
sealed interface BookPhase {
    data object Loading : BookPhase

    data class Loaded(val editionUri: String) : BookPhase

    data object Error : BookPhase

    data object NoResult : BookPhase
}

/** `EntitySummaryView.ViewState`, minus the error case: a failed extract shows nothing. */
sealed interface SummaryState {
    data object Loading : SummaryState

    data class Loaded(val text: String) : SummaryState

    data object Empty : SummaryState
}

/** `MembershipMenuEntry`: one étagère or list of the « … » menu, and whether the book is in it. */
data class MembershipEntry(val id: String, val name: String, val isMember: Boolean)

/**
 * `Features/Book/BookViewModel.swift` + the reads of `BookDetailView` and `BookActions`: resolves a
 * [BookAnchor] to an edition — cache first, then a refresh that upserts in place — and exposes
 * everything the screen draws as one [StateFlow] built from Room.
 *
 * Writes that must outlive the screen (the notes flushed on leave) run on [container]'s
 * application scope rather than [viewModelScope].
 */
class BookViewModel(
    private val container: AppContainer,
    private val anchor: BookAnchor,
) : ViewModel() {
    private val phase: MutableStateFlow<BookPhase> = MutableStateFlow(BookPhase.Loading)
    private val worksWithOtherEditionUris: MutableStateFlow<List<String>> = MutableStateFlow(emptyList())
    private val summaryLoading: MutableStateFlow<Boolean> = MutableStateFlow(true)
    private val backgroundScope: CoroutineScope get() = container.applicationScope

    /** The header while [BookAnchor.BestEditionOfWork] resolves: the search result's title and cover. */
    val placeholder: BookAnchor.BestEditionOfWork? = anchor as? BookAnchor.BestEditionOfWork

    private val editionUri: Flow<String?> = phase.map { (it as? BookPhase.Loaded)?.editionUri }.distinctUntilChanged()

    private val editionWithWorks: Flow<EditionWithWorks?> = editionUri.flatMapLatest { uri ->
        uri?.let(container.entities.entities::observeEditionWithWorks) ?: flowOf(null)
    }

    private val authors: Flow<List<AuthorEntity>> = editionWithWorks
        .map { it?.works.orEmpty().map(WorkEntity::uri) }
        .distinctUntilChanged()
        .flatMapLatest { uris -> if (uris.isEmpty()) flowOf(emptyList()) else container.entities.entities.observeAuthorsOfWorks(uris) }
        .map { list -> list.distinctBy { it.uri }.sortedBy { it.name } }

    private val items: Flow<List<ItemRow>> = editionUri.flatMapLatest { uri ->
        uri?.let(container.inventory::observeItemsOfEdition) ?: flowOf(emptyList())
    }

    private val myUserId: Flow<String?> = container.users.myUserId

    private val ownership: Flow<Pair<ItemRow?, List<ItemRow>>> = combine(items, myUserId) { rows, me ->
        val mine: ItemRow? = rows.firstOrNull { me != null && it.item.ownerId == me }
        mine to rows.filter { it.item.ownerId != me && it.owner != null }
    }

    private val shelves: Flow<List<MembershipEntry>> = combine(myUserId, ownership.map { it.first?.item?.id }.distinctUntilChanged()) { me, itemId ->
        me to itemId
    }.flatMapLatest { (me, itemId) ->
        if (me == null || itemId == null) {
            flowOf(emptyList())
        } else {
            combine(container.shelves.observeShelvesOf(me), container.shelves.observeShelfIdsOf(itemId)) { all: List<ShelfWithItems>, memberIds: List<String> ->
                all.map { MembershipEntry(it.shelf.id, it.shelf.name, it.shelf.id in memberIds) }
            }
        }
    }

    private val lists: Flow<List<MembershipEntry>> = combine(
        container.lists.observeLists(),
        editionWithWorks.map { it?.works?.singleOrNull()?.uri }.distinctUntilChanged(),
    ) { all, workUri ->
        if (workUri == null) {
            emptyList()
        } else {
            all.filter { it.list.type == EntityListType.Work }
                .sortedBy { it.list.name.lowercase() }
                .map { list -> MembershipEntry(list.list.id, list.list.name, list.elements.any { it.uri == workUri }) }
        }
    }

    private val summary: Flow<SummaryState> = editionWithWorks
        .map { it?.edition?.uri to it?.works?.firstOrNull()?.uri }
        .distinctUntilChanged()
        .flatMapLatest { (editionUri, workUri) ->
            val own = editionUri?.let(container.entities::observeExtract) ?: flowOf(null)
            val work = workUri?.let(container.entities::observeExtract) ?: flowOf(null)
            combine(own, work, summaryLoading) { mine, fallback, loading ->
                val text: String? = mine?.content?.takeIf { it.isNotBlank() } ?: fallback?.content?.takeIf { it.isNotBlank() }
                when {
                    text != null -> SummaryState.Loaded(text)
                    loading -> SummaryState.Loading
                    else -> SummaryState.Empty
                }
            }
        }

    private val membership: Flow<Pair<List<MembershipEntry>, List<MembershipEntry>>> = combine(shelves, lists) { s, l -> s to l }

    private val content: Flow<BookUiState> = combine(editionWithWorks, authors, ownership, summary, membership) { edition, authorList, (mine, others), summaryState, (shelfEntries, listEntries) ->
        BookUiState(
            edition = edition?.edition,
            works = edition?.works.orEmpty(),
            authors = authorList,
            myItem = mine,
            othersItems = others,
            summary = summaryState,
            myShelves = shelfEntries,
            myLists = listEntries,
        )
    }

    val state: StateFlow<BookUiState> = combine(phase, content, worksWithOtherEditionUris) { currentPhase, current, otherUris ->
        current.copy(
            phase = currentPhase,
            worksWithOtherEditions = current.works.filter { it.uri in otherUris }.sortedBy { it.title },
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BookUiState())

    init {
        load()
    }

    /** `load(entityModel:modelContext:)`, re-run by « Réessayer ». */
    fun load() {
        viewModelScope.launch {
            phase.value = BookPhase.Loading
            when (anchor) {
                is BookAnchor.BestEditionOfWork -> resolveBestEdition(anchor.uri)
                is BookAnchor.Edition -> loadEdition(anchor.uri)
                is BookAnchor.Item -> {
                    val uri: String? = container.database.inventoryDao().get(anchor.itemId)?.editionUri
                    if (uri == null) phase.value = BookPhase.NoResult else loadEdition(uri)
                }
            }
        }
    }

    private suspend fun loadEdition(uri: String) {
        val cached: EditionEntity? = container.entities.entities.edition(uri)
        if (cached != null) phase.value = BookPhase.Loaded(uri)
        try {
            val refreshed: EditionEntity? = container.entities.refreshEdition(uri)
            when {
                refreshed != null -> phase.value = BookPhase.Loaded(refreshed.uri)
                cached == null -> phase.value = BookPhase.NoResult
            }
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            // A cached copy on screen keeps showing; a failure only matters when there is nothing.
            if (cached == null) phase.value = BookPhase.Error
        }
        afterLoad()
    }

    private suspend fun resolveBestEdition(workUri: String) {
        val resolver = WorkEditionResolver(container.entities, container.database.inventoryDao(), backgroundScope)
        try {
            val edition: EditionEntity? = resolver.resolveBestEdition(workUri)
            phase.value = if (edition == null) BookPhase.NoResult else BookPhase.Loaded(edition.uri)
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            phase.value = BookPhase.Error
        }
        afterLoad()
    }

    /** The summary and the other editions, once the edition is on screen. Failures are swallowed. */
    private suspend fun afterLoad() {
        val uri: String = (phase.value as? BookPhase.Loaded)?.editionUri ?: return
        val workUris: List<String> = container.entities.entities.workUris(uri)
        viewModelScope.launch {
            summaryLoading.value = true
            quietly { container.entities.syncExtract(uri) }
            val hasOwn: Boolean = container.entities.entities.extract(uri)?.content?.isNotBlank() == true
            workUris.firstOrNull()?.takeIf { !hasOwn }?.let { quietly { container.entities.syncExtract(it) } }
            summaryLoading.value = false
        }
        // `reverse-claims` only: knowing that a work has siblings needs their uris, not the editions.
        val withSiblings: List<String> = workUris.filter { workUri ->
            (quietly { container.entities.editionUris(workUri) }?.size ?: 0) > 1
        }
        worksWithOtherEditionUris.value = withSiblings
    }

    // Actions ---------------------------------------------------------------------------------

    fun toggleShelf(entry: MembershipEntry) {
        val itemId: String = state.value.myItem?.item?.id ?: return
        backgroundScope.launch {
            if (entry.isMember) container.shelves.removeItem(entry.id, itemId) else container.shelves.addItem(entry.id, itemId)
        }
    }

    /** Adding is optimistic; removing is server-first, so it answers whether it worked. */
    suspend fun toggleList(entry: MembershipEntry): Boolean {
        val workUri: String = state.value.singleWorkUri ?: return false
        return if (entry.isMember) {
            report { container.lists.removeEntities(entry.id, listOf(workUri)) }
        } else {
            container.lists.addEntities(entry.id, listOf(workUri))
            true
        }
    }

    /** Server-first: `true` once the server said `ok` and the row is gone. */
    suspend fun removeMyItem(): Boolean {
        val itemId: String = state.value.myItem?.item?.id ?: return false
        return report { container.inventory.removeItem(itemId) }
    }

    /** `POST /api/items`, server-first. [AddOutcome.NoUser] is said by the screen; a failure is reported. */
    suspend fun addToInventory(): AddOutcome {
        val uri: String = state.value.edition?.uri ?: return AddOutcome.Failed
        val me: UserEntity = container.users.myUser() ?: return AddOutcome.NoUser
        val ok: Boolean = report { container.inventory.postNewItem(uri, me, TransactionType.Inventorying, listOf(Visibility.Friends)) }
        return if (ok) AddOutcome.Added else AddOutcome.Failed
    }

    fun commitNotes(itemId: String, details: String) {
        backgroundScope.launch { container.inventory.updateDetails(itemId, details) }
    }

    fun updateTransaction(itemId: String, type: TransactionType) {
        backgroundScope.launch { container.inventory.updateTransaction(itemId, type) }
    }

    enum class AddOutcome { Added, NoUser, Failed }

    private suspend fun report(block: suspend () -> Unit): Boolean = try {
        block()
        true
    } catch (cancellation: CancellationException) {
        throw cancellation
    } catch (error: Exception) {
        container.errorReporter.report(error)
        false
    }

    private suspend fun <T> quietly(block: suspend () -> T): T? = try {
        block()
    } catch (cancellation: CancellationException) {
        throw cancellation
    } catch (error: Exception) {
        null
    }
}
