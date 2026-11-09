package studio.lunabee.nouveaurecit.ui.book

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.book.WorkEditionResolver
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.EditionWithWorks
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.data.inventory.InventoryItemTextAttribute
import studio.lunabee.nouveaurecit.data.lists.BookListEntry
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.data.transactions.TransactionRequestTarget
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.ui.lists.ListRowFeed
import studio.lunabee.nouveaurecit.ui.lists.ListsPresentation
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
    /** « Dans les listes »: mine and my friends' lists of works holding the book, the most recently changed first. */
    val inLists: List<BookListRow> = emptyList(),
) {
    /** Listes hold works: an edition behind several works offers no list menu at all. */
    val singleWorkUri: String? get() = works.singleOrNull()?.uri

    /** What the « … » menu reads; `null` until the edition is on screen. */
    val actions: BookActionsState?
        get() = edition?.let {
            BookActionsState(it.uri, myItem?.item?.id, myShelves, myLists, singleWorkUri, TransactionRequestTarget.of(othersItems))
        }
}

/** `BookViewModel.ViewState`. */
sealed interface BookPhase {
    data object Loading : BookPhase

    data class Loaded(val editionUri: String) : BookPhase

    /** [offline] when the call never reached inventaire.io; otherwise the answer could not be read. */
    data class Error(val offline: Boolean) : BookPhase

    data object NoResult : BookPhase
}

/** `EntitySummaryView.ViewState`, minus the error case: a failed extract shows nothing. */
sealed interface SummaryState {
    data object Loading : SummaryState

    data class Loaded(val text: String) : SummaryState

    data object Empty : SummaryState
}

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

    /** The « … » menu's reads and writes, shared with the long press of a book row. */
    val actions: BookActions = BookActions(container, editionUri)

    private val editionWithWorks: Flow<EditionWithWorks?> = actions.editionWithWorks

    private val workUris: Flow<List<String>> = editionWithWorks
        .map { it?.works.orEmpty().map(WorkEntity::uri) }
        .distinctUntilChanged()

    private val authors: Flow<List<AuthorEntity>> = workUris
        .flatMapLatest { uris -> if (uris.isEmpty()) flowOf(emptyList()) else container.entities.entities.observeAuthorsOfWorks(uris) }
        .map { list -> list.distinctBy { it.uri }.sortedBy { it.name } }

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

    /**
     * `BookListsSection`'s two queries: the lists holding one of the works, and my friends — so an add or a
     * removal made elsewhere shows here (ADR 0001). Nothing is fetched but the covers the rows lack.
     */
    private val listEntries: Flow<List<BookListEntry>> = workUris
        .flatMapLatest { uris ->
            if (uris.isEmpty()) {
                flowOf(emptyList())
            } else {
                combine(
                    container.lists.observeListsHolding(uris),
                    container.users.observeByRelation(UserRelation.Friend),
                    container.users.myUserId,
                ) { lists, friends, myId -> BookListEntry.entries(lists, uris, myId, friends) }
            }
        }
        .shareIn(viewModelScope, SharingStarted.WhileSubscribed(), replay = 1)

    private val inLists: Flow<List<BookListRow>> = combine(
        listEntries,
        ListRowFeed(container.entities, viewModelScope).images(listEntries.map { entries -> entries.map(BookListEntry::list) }),
    ) { entries, images ->
        entries.map { BookListRow(ListsPresentation.row(it.list, images, it.owner), it.focusUri) }
    }.onStart { emit(emptyList()) }

    private val membership: Flow<Pair<List<MembershipEntry>, List<MembershipEntry>>> = combine(actions.myShelves, actions.myLists) { s, l -> s to l }

    private val content: Flow<BookUiState> = combine(editionWithWorks, authors, actions.ownership, summary, membership) { edition, authorList, owned, summaryState, (shelfEntries, listEntries) ->
        BookUiState(
            edition = edition?.edition,
            works = edition?.works.orEmpty(),
            authors = authorList,
            myItem = owned.mine,
            othersItems = owned.others,
            summary = summaryState,
            myShelves = shelfEntries,
            myLists = listEntries,
        )
    }

    val state: StateFlow<BookUiState> = combine(phase, content, worksWithOtherEditionUris, inLists) { currentPhase, current, otherUris, lists ->
        current.copy(
            phase = currentPhase,
            worksWithOtherEditions = current.works.filter { it.uri in otherUris }.sortedBy { it.title },
            inLists = lists,
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
            if (cached == null) phase.value = BookPhase.Error(offline = error is NetworkError.Transport)
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
            phase.value = BookPhase.Error(offline = error is NetworkError.Transport)
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

    fun commitText(itemId: String, attribute: InventoryItemTextAttribute, text: String) {
        backgroundScope.launch { container.inventory.updateText(itemId, attribute, text) }
    }

    fun updateTransaction(itemId: String, type: TransactionType) {
        backgroundScope.launch { container.inventory.updateTransaction(itemId, type) }
    }

    private suspend fun <T> quietly(block: suspend () -> T): T? = try {
        block()
    } catch (cancellation: CancellationException) {
        throw cancellation
    } catch (error: Exception) {
        null
    }
}
