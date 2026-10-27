package studio.lunabee.nouveaurecit.ui.editedition

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.EditionClaims
import studio.lunabee.nouveaurecit.data.creation.EditionEdit
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EditionSaveFailure
import studio.lunabee.nouveaurecit.data.creation.EditionSaveResult
import studio.lunabee.nouveaurecit.data.creation.EditionWork
import studio.lunabee.nouveaurecit.data.creation.EntitySearchHit
import studio.lunabee.nouveaurecit.data.creation.EntitySearchType
import studio.lunabee.nouveaurecit.data.creation.NewBookAuthor
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import java.util.UUID

/** Whether the edition has been read yet. */
enum class EditEditionPhase { Loading, Failed, Loaded }

/** Everything « Modifier l'édition » draws, in one immutable value. */
data class EditEditionUiState(
    val phase: EditEditionPhase = EditEditionPhase.Loading,
    /** The form, once the edition is read. Taken back from every save, so a retry sends only what is left. */
    val edit: EditionEdit? = null,
    val pages: PageStack<EditEditionPage> = PageStack(),
    val isSaving: Boolean = false,
    /** What went wrong at the last save, in the reader's terms. `null` until something does. */
    val failure: CreateBookFailure? = null,
    /** Set once everything landed: the screen closes. */
    val isSaved: Boolean = false,
) {
    val canSave: Boolean get() = edit?.isSaveable == true && !isSaving

    /** One work of the form, for « Modifier l'œuvre »; `null` once detached. */
    fun work(id: UUID): WorkEdit? = edit?.works?.firstOrNull { it.id == id }
}

/**
 * `EditEditionFlowView` (iOS features 0049, 0050): « Modifier l'édition », from reading the edition fresh
 * to writing what landed back into the store.
 *
 * The store is read for nothing but the edition's cover, which stands in for its works' in their rows:
 * what the form starts from comes from the server ([EditionClaims]), since each change names the value
 * it replaces. [storeUri] is the uri the store keeps the edition under — `isbn:…` for one opened from
 * its ISBN — where the edit holds the canonical `inv:…`.
 *
 * **Nothing is optimistic.** The save waits for the server; a full success writes into the store and
 * closes the form, a partial one writes what landed — that is what inventaire.io now shows — and keeps
 * the form, with what landed moved out of what the next try sends.
 */
class EditEditionViewModel(
    private val container: AppContainer,
    private val storeUri: String,
) : ViewModel() {
    private val _state: MutableStateFlow<EditEditionUiState> = MutableStateFlow(EditEditionUiState())
    val state: StateFlow<EditEditionUiState> = _state.asStateFlow()

    /** The searches of the entity and author pickers: the type follows the page on top. */
    val entitySearch: DebouncedSearch<EntitySearchHit> = DebouncedSearch(viewModelScope) { query ->
        val type: EntitySearchType = currentSearchType() ?: return@DebouncedSearch emptyList()
        container.creation.searchEntities(query, type)
    }

    /** « De quelle œuvre est-ce une édition ? »: each work found completed by its authors and year. */
    val workSearch: DebouncedSearch<WorkCandidate> = DebouncedSearch(viewModelScope) { query -> container.creation.searchWorks(query) }

    init {
        load()
    }

    /** Reads the edition's claims, then its works — what « Modifier l'œuvre » starts from and compares against. */
    fun load() {
        _state.update { it.copy(phase = EditEditionPhase.Loading) }
        viewModelScope.launch {
            try {
                val claims: EditionClaims = container.creation.editableEdition(storeUri)
                val local: EditionEntity? = container.entities.entities.edition(storeUri)
                val works: List<EditionWork> = container.creation.describeEditionWorks(claims.workUris).map { work ->
                    work.copy(imageUrl = work.imageUrl ?: local?.image)
                }
                _state.update { it.copy(phase = EditEditionPhase.Loaded, edit = EditionEdit(claims, works)) }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                _state.update { it.copy(phase = EditEditionPhase.Failed) }
            }
        }
    }

    // Pages

    /** Back one page; `false` on the form itself, whose way back is leaving the screen. Nothing moves while saving. */
    fun back(): Boolean {
        val current: EditEditionUiState = _state.value
        if (current.isSaving) return true
        if (current.pages.isEmpty) return false
        _state.update { it.copy(pages = it.pages.pop()) }
        return true
    }

    fun pop(count: Int) = _state.update { it.copy(pages = it.pages.pop(count)) }

    fun openHelp() = push(EditEditionPage.Help)

    fun openWorkSearch() {
        workSearch.reset()
        push(EditEditionPage.WorkSearch)
    }

    fun openWork(id: UUID) = push(EditEditionPage.WorkDetail(id))

    fun openAuthorSearch(workId: UUID) {
        entitySearch.reset()
        push(EditEditionPage.WorkAuthor(workId))
    }

    /** Pushes what changes [property]: the date's page, its values, or the search. */
    fun openProperty(property: EditionProperty) {
        val properties: EditionProperties = _state.value.edit?.properties ?: return
        pushProperty(EditionPropertyStep.opening(property, properties))
    }

    fun openIdentifierCatalog(group: EditionProperty.Group) = pushProperty(EditionPropertyStep.IdentifierCatalog(group))

    fun pushProperty(step: EditionPropertyStep) {
        if (step is EditionPropertyStep.Picker) entitySearch.reset()
        push(EditEditionPage.Property(step))
    }

    // The form

    fun setTitle(title: String) = updateEdit { it.copy(title = title) }

    fun setSubtitle(subtitle: String) = updateEdit { it.copy(subtitle = subtitle) }

    /** A local picture replaces the cover; `null` takes it away. */
    fun setCover(path: String?) = updateEdit { it.withCover(path) }

    fun setProperties(properties: EditionProperties) = updateEdit { it.copy(properties = properties) }

    fun detachWork(id: UUID) = updateEdit { it.detachWork(id) }

    /** A work picked from the search: added, and back to the form. */
    fun addWork(candidate: WorkCandidate) {
        updateEdit { it.addWork(candidate) }
        pop(1)
    }

    /** None of the works found: one is created, and its own page replaces the search — it needs an author. */
    fun startNewWork(query: String) {
        val started: EditionEdit = _state.value.edit?.startNewWork(query) ?: return
        val id: UUID = started.works.last().id
        _state.update { it.copy(edit = started, pages = it.pages.replaceTop(EditEditionPage.WorkDetail(id))) }
    }

    /** A Wikidata work's title is shown, not changed. */
    fun setWorkTitle(id: UUID, title: String) = updateEdit { edit ->
        edit.updatingWork(id) { work -> if (work.isEditable) work.copy(title = title) else work }
    }

    /** An author picked or created: added to the work, and back to « Modifier l'œuvre ». */
    fun addAuthor(workId: UUID, author: NewBookAuthor) {
        updateEdit { edit -> edit.updatingWork(workId) { it.addAuthor(author) } }
        pop(1)
    }

    fun removeAuthor(workId: UUID, index: Int) = updateEdit { edit -> edit.updatingWork(workId) { it.removeAuthors(setOf(index)) } }

    // Saving

    /**
     * Sends what changed, then shows it on the book screen. A failure leaves the form as it is, with
     * everything typed still there, and what did land already moved out of what the next try sends.
     */
    fun save() {
        val current: EditEditionUiState = _state.value
        val edit: EditionEdit = current.edit ?: return
        if (!current.canSave) return
        _state.update { it.copy(isSaving = true, failure = null) }
        viewModelScope.launch {
            val result: EditionSaveResult = container.creation.saveEdition(edit)
            show(result.edit, since = edit)
            when (result) {
                is EditionSaveResult.Saved -> _state.update { it.copy(edit = result.edit, isSaving = false, isSaved = true) }
                is EditionSaveFailure -> _state.update { it.copy(edit = result.edit, isSaving = false, failure = result.failure) }
            }
        }
    }

    /** What landed, written into the store; a store that cannot be written does not undo the save. */
    private suspend fun show(after: EditionEdit, since: EditionEdit) {
        try {
            container.entities.applyEditionEdit(storeUri, after, since)
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (_: Exception) {
            // The server holds the change; the next refresh of the book brings it.
        }
    }

    private fun push(page: EditEditionPage) = _state.update { it.copy(pages = it.pages.push(page)) }

    /** The draft is not touched while a save runs: the save's answer replaces it. */
    private fun updateEdit(transform: (EditionEdit) -> EditionEdit) = _state.update { current ->
        val edit: EditionEdit = current.edit ?: return@update current
        if (current.isSaving) current else current.copy(edit = transform(edit))
    }

    private fun currentSearchType(): EntitySearchType? = when (val page: EditEditionPage? = _state.value.pages.top) {
        is EditEditionPage.WorkAuthor -> EntitySearchType.Humans
        is EditEditionPage.Property -> (page.step as? EditionPropertyStep.Picker)?.let { EditionProperty.named(it.propertyUri)?.searchType }
        else -> null
    }
}
