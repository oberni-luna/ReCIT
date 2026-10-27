package studio.lunabee.nouveaurecit.ui.createbook

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.SearchResult
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.NewBookAuthor
import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.data.scan.ScannedBook
import studio.lunabee.nouveaurecit.network.ImageUrl

/** The three pages of « Nouveau livre »: the form, the author picker, and « Ce livre est connu ». */
enum class CreateBookPage { Form, Author, Work }

/** Everything « Nouveau livre » draws, in one immutable value. */
data class CreateBookState(
    val draft: NewBookDraft,
    val page: CreateBookPage = CreateBookPage.Form,
    /** What went wrong last time, in the user's terms. `null` until something does. */
    val failure: CreateBookFailure? = null,
    val isPublishing: Boolean = false,
    /** The work the dry run recognised, shown by [CreateBookPage.Work]. */
    val recognisedWorkUri: String? = null,
    val authorQuery: String = "",
    val authorResults: List<SearchResult> = emptyList(),
    val hasSearchedAuthors: Boolean = false,
)

/**
 * `CreateBookView`'s state and actions (feature 0020): one creation, from the form that opens on an
 * unknown barcode to the book filed in the inventory.
 *
 * Owned by the scanning session, not by a screen: `ScanViewModel` opens one in its own scope and drops
 * it when the form goes, so rotation keeps it and nothing outlives the session. [onCreated] is told the
 * book once it exists *and* is filed — only on a full success.
 *
 * Publishing waits for the server, every step of it. A failure leaves the draft exactly as it was:
 * nothing was created on inventaire.io, so trying again makes no duplicate.
 */
class CreateBookSession(
    private val container: AppContainer,
    parentScope: CoroutineScope,
    draft: NewBookDraft,
    private val onCreated: (ScannedBook) -> Unit,
) {
    private val job: Job = Job(parentScope.coroutineContext[Job])
    private val scope: CoroutineScope = CoroutineScope(parentScope.coroutineContext + job)
    private val _state: MutableStateFlow<CreateBookState> = MutableStateFlow(CreateBookState(draft = draft))
    val state: StateFlow<CreateBookState> = _state.asStateFlow()

    val draft: NewBookDraft get() = _state.value.draft

    private var searchJob: Job? = null

    init {
        // Asked once, as the form opens, and never blocking: the user can type the whole book before
        // the answer lands, and publish whether or not it does.
        if (draft.language == null) {
            scope.launch {
                val language = container.creation.editionLanguage(draft.isbn) ?: return@launch
                updateDraft { it.withLanguage(language) }
            }
        }
    }

    fun setTitle(title: String) = updateDraft { it.copy(title = title) }

    /** A new photograph invalidates one already uploaded on a failed attempt: the next publication sends it. */
    fun setCover(path: String) = updateDraft { it.copy(coverImagePath = path, coverImageUrl = null) }

    /** The picker opens on the name already chosen: coming back to change an author starts from that author. */
    fun openAuthorPicker() {
        _state.update { it.copy(page = CreateBookPage.Author) }
        if (_state.value.authorQuery.isEmpty()) searchAuthors(draft.authors.firstOrNull()?.name.orEmpty())
    }

    /** Back one page; `false` on the form itself, whose way back is closing. */
    fun back(): Boolean {
        if (_state.value.page == CreateBookPage.Form) return false
        _state.update { it.copy(page = CreateBookPage.Form) }
        return true
    }

    /**
     * The search is the app's own, restricted to people — `resolve` reconciles a finished entry, it does
     * not search as you type. Cancelling the previous search is the debounce.
     */
    fun searchAuthors(query: String) {
        _state.update { it.copy(authorQuery = query) }
        searchJob?.cancel()
        val trimmed: String = query.trim()
        if (trimmed.length < MIN_QUERY_LENGTH) {
            _state.update { it.copy(authorResults = emptyList(), hasSearchedAuthors = false) }
            return
        }
        searchJob = scope.launch {
            delay(SEARCH_DEBOUNCE_MILLIS)
            // A failed search is no dead end: the « Créer » row is always there.
            val results: List<SearchResult> = try {
                container.search.search(trimmed, setOf(SearchResult.Type.Humans))
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                emptyList()
            }
            _state.update { it.copy(authorResults = results, hasSearchedAuthors = true) }
        }
    }

    /** An author inventaire.io has: named by uri from now on, so the server reuses it. */
    fun chooseAuthor(result: SearchResult) {
        updateDraft { it.copy(authors = listOf(NewBookAuthor(name = result.label, uri = result.uri, description = result.description))) }
        _state.update { it.copy(page = CreateBookPage.Form) }
    }

    /** An author nobody has entered yet: described by label, created with the book. */
    fun createAuthor() {
        val name: String = _state.value.authorQuery.trim()
        if (name.isEmpty()) return
        updateDraft { it.copy(authors = listOf(NewBookAuthor(name = name))) }
        _state.update { it.copy(page = CreateBookPage.Form) }
    }

    /** « Une édition de plus » (the uri) or « Non, c'est un autre livre » (`null`). */
    fun chooseWork(uri: String?) = updateDraft { it.copy(workUri = uri) }

    /**
     * Asks before writing. The dry run writes nothing and may recognise a work this book is an edition
     * of — the user is then shown it, and publishes from there. Asked at most once per draft.
     */
    fun publish() {
        if (_state.value.isPublishing || !draft.isPublishable) return
        _state.update { it.copy(isPublishing = true) }
        scope.launch {
            if (!draft.hasAnsweredWorkQuestion) {
                val workUri: String? = container.creation.recogniseWork(draft)
                if (workUri != null) {
                    // The safe answer is the default: one more edition of the work that exists.
                    updateDraft { it.copy(workUri = workUri, hasAnsweredWorkQuestion = true) }
                    _state.update { it.copy(isPublishing = false, page = CreateBookPage.Work, recognisedWorkUri = workUri) }
                    launch { runCatching { container.entities.refreshWork(workUri) } }
                    return@launch
                }
            }
            create()
        }
    }

    /** « Publier cette édition », with whatever has just been decided. */
    fun publishEdition() {
        if (_state.value.isPublishing) return
        _state.update { it.copy(isPublishing = true) }
        scope.launch { create() }
    }

    fun cancel() = job.cancel()

    /** Creates the book, then files it — in that order: the second needs the canonical uri the first answers. */
    private suspend fun create() {
        _state.update { it.copy(failure = null) }
        try {
            val me: UserEntity = container.users.myUser() ?: throw MissingUser()
            // Before the publication, since its url goes in the same request — and never in its way.
            val path: String? = draft.coverImagePath
            if (path != null && draft.coverImageUrl == null) {
                val bytes: ByteArray? = CoverPhoto.bytes(path)
                val url: String? = bytes?.let { container.creation.uploadCover(it) }
                updateDraft { it.copy(coverImageUrl = url) }
            }
            // The publishers, collections and people nobody has entered yet exist before `resolve` names
            // them; each is kept in the draft as it lands, so a failure further on does not create it twice.
            container.creation.createPendingEntities(draft.properties, draft.labelLanguage) { id, created ->
                updateDraft { it.entityCreated(id, created) }
            }
            val uri: String = container.creation.createEdition(draft)
            // Same defaults as the scanner's own add, so a created book is indistinguishable afterwards.
            container.inventory.postNewItem(uri, me, TransactionType.Inventorying, listOf(Visibility.Friends))
            _state.update { it.copy(isPublishing = false) }
            onCreated(
                ScannedBook(
                    uri = uri,
                    title = draft.trimmedTitle,
                    authors = draft.chosenWork?.authors ?: draft.namedAuthors.map { it.trimmedName },
                    coverImageUrl = ImageUrl.absolute(draft.coverImageUrl),
                    code = draft.isbn,
                ),
            )
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            // Said in the form, beside the button that retries: the draft is still there.
            val failure: CreateBookFailure = if (error is MissingUser) CreateBookFailure.NeedsAccount else CreateBookFailure.from(error)
            _state.update { it.copy(isPublishing = false, failure = failure, page = CreateBookPage.Form) }
        }
    }

    private fun updateDraft(transform: (NewBookDraft) -> NewBookDraft) = _state.update { it.copy(draft = transform(it.draft)) }

    private class MissingUser : Exception()

    private companion object {
        const val MIN_QUERY_LENGTH: Int = 2
        const val SEARCH_DEBOUNCE_MILLIS: Long = 300
    }
}
