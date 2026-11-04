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
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyCatalogue
import studio.lunabee.nouveaurecit.data.creation.EditionSaveFailure
import studio.lunabee.nouveaurecit.data.creation.EditionSaveResult
import studio.lunabee.nouveaurecit.data.creation.EditionWork
import studio.lunabee.nouveaurecit.data.creation.EntityEdit
import studio.lunabee.nouveaurecit.data.creation.EntitySaveResult
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
    /** The works and people pushed over the form, as their pages change them — keyed by uri, for as long as their page is on the stack. */
    val entities: Map<String, EntityEdit> = emptyMap(),
    /** The works and people that could not be read. */
    val unreadableEntities: Set<String> = emptySet(),
    /** What went wrong at the last save of each of them. */
    val entityFailures: Map<String, CreateBookFailure> = emptyMap(),
    /** The work or person being saved; nothing moves until the server has answered. */
    val savingEntity: String? = null,
    /** The work or person whose page asks « Quitter sans enregistrer ? ». */
    val leavingEntity: String? = null,
) {
    val canSave: Boolean get() = edit?.isSaveable == true && !isSaving

    /** Whether a save of the edition or of one of its entities runs. */
    val isBusy: Boolean get() = isSaving || savingEntity != null

    /** One work being created, for its page; `null` once detached. */
    fun work(id: UUID): WorkEdit? = edit?.works?.firstOrNull { it.id == id }
}

/**
 * `EditEditionFlowView` (iOS features 0049, 0050, 0057): « Modifier l'édition », from reading the edition
 * fresh to writing what landed back into the store — and « Modifier l'œuvre » and « Modifier
 * l'auteur·ice » pushed over it, each read fresh and saved alone by its own « Enregistrer ».
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

    /** The searches of the entity and author pickers: the types follow the page on top. */
    val entitySearch: DebouncedSearch<EntitySearchHit> = DebouncedSearch(viewModelScope) { query ->
        container.creation.searchEntities(query, currentSearchTypes())
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

    /**
     * Back one page; `false` on the form itself, whose way back is leaving the screen. Nothing moves while
     * saving, and a work's or a person's page with changes not saved asks first.
     */
    fun back(): Boolean {
        val current: EditEditionUiState = _state.value
        if (current.isBusy) return true
        val top: EditEditionPage = current.pages.top ?: return false
        if (top is EditEditionPage.Entity && current.entities[top.uri]?.hasChanges == true) {
            _state.update { it.copy(leavingEntity = top.uri) }
        } else {
            pop(1)
        }
        return true
    }

    fun pop(count: Int) = _state.update { it.withPages(it.pages.pop(count)) }

    fun openHelp() = push(EditEditionPage.Help)

    fun openWorkSearch() {
        workSearch.reset()
        push(EditEditionPage.WorkSearch)
    }

    /**
     * Pushes the page of a work of « Édition de »: the title and authors of one being created, the whole
     * of « Modifier l'œuvre » for one of inventaire.io's own. A Wikidata work has none.
     */
    fun openWork(id: UUID) {
        val work: WorkEdit = _state.value.work(id) ?: return
        val uri: String? = work.uri
        when {
            work.isNew -> push(EditEditionPage.WorkDetail(id))
            uri != null && EntityEdit.canEdit(uri) -> openEntity(uri)
        }
    }

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

    // A work or a person

    /** Pushes « Modifier l'œuvre » or « Modifier l'auteur·ice », and reads the entity unless its page is on the stack already. */
    fun openEntity(uri: String) {
        if (!EntityEdit.canEdit(uri)) return
        push(EditEditionPage.Entity(uri))
        if (uri !in _state.value.entities) loadEntity(uri)
    }

    /** Reads the work or person fresh: what its page starts from and compares against. */
    fun loadEntity(uri: String) {
        _state.update { it.copy(unreadableEntities = it.unreadableEntities - uri) }
        viewModelScope.launch {
            try {
                val edit: EntityEdit = container.creation.editableEntity(uri)
                _state.update { current ->
                    if (current.pages.pages.contains(EditEditionPage.Entity(uri))) current.copy(entities = current.entities + (uri to edit)) else current
                }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                _state.update { it.copy(unreadableEntities = it.unreadableEntities + uri) }
            }
        }
    }

    /** Pushes what changes one of the entity's properties: its values, a date, a list of choices, or the search. */
    fun openEntityProperty(uri: String, property: EditionProperty) {
        val properties: EditionProperties = _state.value.entities[uri]?.properties ?: return
        pushEntityProperty(uri, EditionPropertyStep.opening(property, properties))
    }

    fun pickEntityProperty(uri: String, property: EditionProperty) = pushEntityProperty(uri, EditionPropertyStep.Picker(property.uri))

    fun openEntityIdentifierCatalog(uri: String, group: EditionProperty.Group) = pushEntityProperty(uri, EditionPropertyStep.IdentifierCatalog(group))

    fun pushEntityProperty(uri: String, step: EditionPropertyStep) {
        if (step is EditionPropertyStep.Picker) entitySearch.reset()
        push(EditEditionPage.EntityProperty(uri, step))
    }

    fun setEntityProperties(uri: String, properties: EditionProperties) = updateEntity(uri) { it.copy(properties = properties) }

    fun setEntityLabel(uri: String, language: String, value: String) = updateEntity(uri) { it.withLabel(language, value) }

    fun addEntityLabel(uri: String, language: String) = updateEntity(uri) { it.addingLabel(language) }

    /** « Quitter » over unsaved changes: the page goes, and what it had changed with it. */
    fun leaveEntity(uri: String) = _state.update { it.withPages(it.pages.popTo(EditEditionPage.Entity(uri))).copy(leavingEntity = null) }

    fun stayOnEntity() = _state.update { it.copy(leavingEntity = null) }

    /**
     * Sends what the work's or the person's page changed, shows it on the pages beneath and in the store,
     * then goes back. A failure leaves the page as it is, everything typed still there, and what did land
     * already moved out of what the next try sends.
     */
    fun saveEntity(uri: String) {
        val current: EditEditionUiState = _state.value
        val edit: EntityEdit = current.entities[uri] ?: return
        if (current.isBusy || !edit.isSaveable) return
        _state.update { it.copy(savingEntity = uri, entityFailures = it.entityFailures - uri) }
        viewModelScope.launch {
            val result: EntitySaveResult = container.creation.saveEntity(edit)
            showEntity(result.edit, since = edit)
            _state.update { state ->
                val saved: EditEditionUiState = state.copy(savingEntity = null, entities = state.entities + (uri to result.edit))
                when (result) {
                    is EntitySaveResult.Saved -> saved.withPages(saved.pages.popTo(EditEditionPage.Entity(uri)))
                    is EntitySaveResult.Failed -> saved.copy(entityFailures = saved.entityFailures + (uri to result.failure))
                }
            }
        }
    }

    /**
     * Shows a work or person as far as it was saved on the pages beneath it — a work's row in « Édition
     * de », a person's name wherever it is named — and in the store, which the book screen reads.
     */
    private suspend fun showEntity(after: EntityEdit, since: EntityEdit) {
        if (after == since) return
        _state.update { state ->
            when (after.catalogue) {
                EditionPropertyCatalogue.Work -> state.copy(edit = state.edit?.workSaved(after.editionWork))
                EditionPropertyCatalogue.Human -> state.copy(
                    edit = state.edit?.rename(after.uri, after.displayName),
                    entities = state.entities.mapValues { (uri, entity) -> if (uri == after.uri) entity else entity.rename(after.uri, after.displayName) },
                )
                EditionPropertyCatalogue.Edition -> state
            }
        }
        try {
            container.entities.applyEntityEdit(after, since)
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (_: Exception) {
            // The server holds the change; the next refresh of the book brings it.
        }
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
        _state.update { it.copy(edit = started).withPages(it.pages.replaceTop(EditEditionPage.WorkDetail(id))) }
    }

    fun setWorkTitle(id: UUID, title: String) = updateEdit { edit -> edit.updatingWork(id) { it.copy(title = title) } }

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
        if (!current.canSave || current.isBusy) return
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

    /** The entity's draft is not touched while a save runs: the save's answer replaces it. */
    private fun updateEntity(uri: String, transform: (EntityEdit) -> EntityEdit) = _state.update { current ->
        val edit: EntityEdit = current.entities[uri] ?: return@update current
        if (current.isBusy) current else current.copy(entities = current.entities + (uri to transform(edit)))
    }

    /** The draft is not touched while a save runs: the save's answer replaces it. */
    private fun updateEdit(transform: (EditionEdit) -> EditionEdit) = _state.update { current ->
        val edit: EditionEdit = current.edit ?: return@update current
        if (current.isBusy) current else current.copy(edit = transform(edit))
    }

    private fun currentSearchTypes(): List<EntitySearchType> {
        val state: EditEditionUiState = _state.value
        return when (val page: EditEditionPage? = state.pages.top) {
            is EditEditionPage.WorkAuthor -> listOf(EntitySearchType.Humans)
            is EditEditionPage.Property -> searchTypes(page.step, state.edit?.properties)
            is EditEditionPage.EntityProperty -> searchTypes(page.step, state.entities[page.uri]?.properties)
            else -> emptyList()
        }
    }

    private fun searchTypes(step: EditionPropertyStep, properties: EditionProperties?): List<EntitySearchType> {
        val picker: EditionPropertyStep.Picker = step as? EditionPropertyStep.Picker ?: return emptyList()
        return properties?.catalogue?.property(picker.propertyUri)?.searchTypes.orEmpty()
    }
}

/**
 * The state with [pages] on the stack, less what the works' and people's pages no longer on it were
 * changing: going back to one reads it afresh.
 */
private fun EditEditionUiState.withPages(pages: PageStack<EditEditionPage>): EditEditionUiState {
    val shown: Set<String> = pages.pages.mapNotNull { (it as? EditEditionPage.Entity)?.uri }.toSet()
    return copy(
        pages = pages,
        entities = entities.filterKeys { it in shown },
        unreadableEntities = unreadableEntities.intersect(shown),
        entityFailures = entityFailures.filterKeys { it in shown },
    )
}
