package studio.lunabee.nouveaurecit.ui.createbook

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EntitySearchHit
import studio.lunabee.nouveaurecit.data.creation.EntitySearchType
import studio.lunabee.nouveaurecit.data.creation.NewBookAuthor
import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.data.scan.ScannedBook
import studio.lunabee.nouveaurecit.network.ImageUrl
import studio.lunabee.nouveaurecit.ui.editedition.DebouncedSearch
import studio.lunabee.nouveaurecit.ui.editedition.EditionPropertyStep
import studio.lunabee.nouveaurecit.ui.editedition.PageStack

/** Everything « Nouveau livre » draws, in one immutable value. */
data class CreateBookState(
    val draft: NewBookDraft,
    /** The pages over the work search; empty is the search. */
    val pages: PageStack<CreateBookPage> = CreateBookPage.resuming(draft),
    /** What went wrong last time, in the user's terms. `null` until something does. */
    val failure: CreateBookFailure? = null,
    val isPublishing: Boolean = false,
)

/**
 * `NewBookFlowView` (features 0020, iOS 0047 and 0050): one creation, from the work search that opens on
 * an unknown barcode to the book filed in the inventory — « Nouvelle édition » for the edition, « Nouvelle
 * œuvre » for a work nobody has entered, « Œuvre déjà connue » when the dry run recognises it after all.
 * Pages are a stack in this state, as « Modifier l'édition » keeps its own.
 *
 * Owned by the scanning session, not by a screen: `ScanViewModel` opens one in its own scope and drops
 * it when the form goes, so rotation keeps it and nothing outlives the session. [onCreated] is told the
 * book once it exists *and* is filed — only on a full success.
 *
 * Publishing waits for the server, every step of it, and nothing is touched or left while it does. A
 * failure leaves the draft as it was, with the entities that did get created recorded in it: trying again
 * makes no duplicate.
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

    /** « De quel livre s'agit-il ? »: each work found completed by its authors and year. */
    val workSearch: DebouncedSearch<WorkCandidate> = DebouncedSearch(scope) { query -> container.creation.searchWorks(query) }

    /** The searches of the author and entity pickers: the type follows the page on top. */
    val entitySearch: DebouncedSearch<EntitySearchHit> = DebouncedSearch(scope) { query ->
        val type: EntitySearchType = currentSearchType() ?: return@DebouncedSearch emptyList()
        container.creation.searchEntities(query, type)
    }

    init {
        // Asked once, as the creation opens, and never blocking: the user can describe the whole book
        // before the answer lands, and publish whether or not it does.
        if (draft.language == null) {
            scope.launch {
                val language = container.creation.editionLanguage(draft.isbn) ?: return@launch
                record { it.withLanguage(language) }
            }
        }
    }

    // Pages

    /** Back one page; `false` on the search itself, whose way back is closing. Nothing moves while publishing. */
    fun back(): Boolean {
        val current: CreateBookState = _state.value
        if (current.isPublishing) return true
        val top: CreateBookPage = current.pages.top ?: return false
        _state.update { state ->
            val draft: NewBookDraft = if (top is CreateBookPage.RecognisedWork) state.draft.leavingRecognised(top.uri) else state.draft
            state.copy(draft = draft, pages = state.pages.pop())
        }
        return true
    }

    fun pop(count: Int) = _state.update { it.copy(pages = it.pages.pop(count)) }

    fun openHelp() = push(CreateBookPage.Help)

    /** A work found, touched in « Édition de »: back to the search, to pick another. */
    fun findWork() = _state.update { if (it.isPublishing) it else it.copy(pages = PageStack()) }

    fun openNewWork() = push(CreateBookPage.NewWork)

    fun openNewWorkAuthor() {
        entitySearch.reset()
        push(CreateBookPage.NewWorkAuthor)
    }

    /** Pushes what changes [property]: the date's page, its values, or the search. */
    fun openProperty(property: EditionProperty) = pushProperty(EditionPropertyStep.opening(property, draft.properties))

    fun openIdentifierCatalog(group: EditionProperty.Group) = pushProperty(EditionPropertyStep.IdentifierCatalog(group))

    fun pushProperty(step: EditionPropertyStep) {
        if (step is EditionPropertyStep.Picker) entitySearch.reset()
        push(CreateBookPage.Property(step))
    }

    // The work

    /** A work inventaire.io already has: only the edition is left to describe. */
    fun chooseWork(work: WorkCandidate) = _state.update { state ->
        if (state.isPublishing) state else state.copy(draft = state.draft.choose(work), failure = null, pages = CreateBookPage.afterChoosingWork)
    }

    /** None of the works fits: one is described, named after the search, on its own page over the edition's form. */
    fun startNewWork(query: String) = _state.update { state ->
        if (state.isPublishing) state else state.copy(draft = state.draft.startNewWork(query), failure = null, pages = CreateBookPage.afterStartingNewWork)
    }

    fun detachWork() = edit { it.detachWork() }

    fun setWorkTitle(title: String) = edit { it.renameWork(title) }

    /** An author picked or created: added to the work, and back to « Nouvelle œuvre ». */
    fun addAuthor(author: NewBookAuthor) {
        edit { it.addAuthor(author) }
        pop(1)
    }

    fun removeAuthor(index: Int) = edit { it.removeAuthor(index) }

    /** « Une édition de cette œuvre » (the uri) or « Non, une autre œuvre » (`null`). */
    fun answerRecognisedWork(uri: String?) = edit { it.copy(workUri = uri) }

    // The edition

    fun setTitle(title: String) = edit { it.copy(title = title) }

    fun setSubtitle(subtitle: String) = edit { it.copy(subtitle = subtitle) }

    /** A new picture invalidates one uploaded on a failed attempt: the next publication sends it. `null` takes it away. */
    fun setCover(path: String?) = edit { it.copy(coverImagePath = path, coverImageUrl = null) }

    fun setProperties(properties: EditionProperties) = edit { it.copy(properties = properties) }

    // Publishing

    /**
     * Asks before writing, for a work being created: the dry run writes nothing and may recognise a work
     * this book is an edition of, which the search did not offer — the user is then shown it, and
     * publishes from there. Asked at most once per draft.
     */
    fun publish() {
        val current: CreateBookState = _state.value
        if (current.isPublishing || !current.draft.isPublishable) return
        _state.update { it.copy(isPublishing = true) }
        scope.launch {
            if (draft.asksWhichWork) {
                val workUri: String? = container.creation.recogniseWork(draft)
                if (workUri != null) {
                    _state.update {
                        it.copy(draft = it.draft.recognised(workUri), isPublishing = false, pages = it.pages.push(CreateBookPage.RecognisedWork(workUri)))
                    }
                    launch { runCatching { container.entities.refreshWork(workUri) } }
                    return@launch
                }
            }
            create()
        }
    }

    /** « Publier » on « Œuvre déjà connue », with whatever has just been decided there. */
    fun publishEdition() {
        val current: CreateBookState = _state.value
        if (current.isPublishing || !current.draft.isPublishable) return
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
                record { it.copy(coverImageUrl = url) }
            }
            // The publishers, collections and people nobody has entered yet exist before `resolve` names
            // them; each is kept in the draft as it lands, so a failure further on does not create it twice.
            container.creation.createPendingEntities(draft.properties, draft.labelLanguage) { id, created ->
                record { it.entityCreated(id, created) }
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
            // Said on the page that published, beside the button that retries: the draft is still there.
            val failure: CreateBookFailure = if (error is MissingUser) CreateBookFailure.NeedsAccount else CreateBookFailure.from(error)
            _state.update { it.copy(isPublishing = false, failure = failure) }
        }
    }

    private fun push(page: CreateBookPage) = _state.update { if (it.isPublishing) it else it.copy(pages = it.pages.push(page)) }

    /** What the user changes: nothing is touched while a publication runs. */
    private fun edit(transform: (NewBookDraft) -> NewBookDraft) = _state.update { if (it.isPublishing) it else it.copy(draft = transform(it.draft)) }

    /** What the publication itself, or the ISBN's answer, writes into the draft. */
    private fun record(transform: (NewBookDraft) -> NewBookDraft) = _state.update { it.copy(draft = transform(it.draft)) }

    private fun currentSearchType(): EntitySearchType? = when (val page: CreateBookPage? = _state.value.pages.top) {
        CreateBookPage.NewWorkAuthor -> EntitySearchType.Humans
        is CreateBookPage.Property -> (page.step as? EditionPropertyStep.Picker)?.let { EditionProperty.named(it.propertyUri)?.searchType }
        else -> null
    }

    private class MissingUser : Exception()
}
