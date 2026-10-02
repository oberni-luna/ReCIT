package studio.lunabee.nouveaurecit.ui.book

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.data.db.WorkWithAuthors
import studio.lunabee.nouveaurecit.data.model.EntityListType

/** `WorkEditionGatewayView.ViewState`, reduced to what decides the frame. */
sealed interface WorkPhase {
    data object LoadingWork : WorkPhase

    /** The work is known; [editionsSynced] says whether its editions have been asked for yet. */
    data class Loaded(val editionsSynced: Boolean) : WorkPhase

    data class Error(val message: String?) : WorkPhase
}

data class WorkUiState(
    val phase: WorkPhase = WorkPhase.LoadingWork,
    val work: WorkEntity? = null,
    val authors: List<AuthorEntity> = emptyList(),
    val editions: List<EditionEntity> = emptyList(),
    val summary: SummaryState = SummaryState.Loading,
    val myLists: List<MembershipEntry> = emptyList(),
) {
    /**
     * The one edition to open inline — only once the editions were synced, so a work the inventory
     * sync knows through a single copy does not open that copy and then jump to the picker.
     */
    val singleEditionUri: String?
        get() = editions.singleOrNull()?.uri?.takeIf { (phase as? WorkPhase.Loaded)?.editionsSynced == true }
}

/**
 * `WorkEditionGatewayView.load()`: the cached work at once, then `refreshWork`, then
 * `syncWorkEditions`. Everything drawn comes from Room.
 */
class WorkViewModel(
    private val container: AppContainer,
    private val workUri: String,
) : ViewModel() {
    private val phase: MutableStateFlow<WorkPhase> = MutableStateFlow(WorkPhase.LoadingWork)
    private val summaryLoading: MutableStateFlow<Boolean> = MutableStateFlow(true)

    private val lists: Flow<List<MembershipEntry>> = container.lists.observeLists().map { all ->
        all.filter { it.list.type == EntityListType.Work }
            .sortedBy { it.list.name.lowercase() }
            .map { list -> MembershipEntry(list.list.id, list.list.name, list.elements.any { it.uri == workUri }) }
    }

    private val summary = combine(container.entities.observeExtract(workUri), summaryLoading) { extract, loading ->
        val text: String? = extract?.content?.takeIf { it.isNotBlank() }
        when {
            text != null -> SummaryState.Loaded(text)
            loading -> SummaryState.Loading
            else -> SummaryState.Empty
        }
    }

    val state: StateFlow<WorkUiState> = combine(
        phase,
        container.entities.entities.observeWorkWithAuthors(workUri),
        container.entities.entities.observeEditionsOfWork(workUri),
        summary,
        lists,
    ) { currentPhase, work: WorkWithAuthors?, editions, summaryState, listEntries ->
        WorkUiState(
            phase = currentPhase,
            work = work?.work,
            authors = work?.authors.orEmpty().sortedBy { it.name },
            editions = editions.sortedBy { it.title.lowercase() },
            summary = summaryState,
            myLists = listEntries,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), WorkUiState())

    init {
        load()
    }

    private fun load() {
        viewModelScope.launch {
            val cached: WorkEntity? = container.entities.entities.work(workUri)
            if (cached != null) phase.value = WorkPhase.Loaded(editionsSynced = false)
            launch {
                runCatching { container.entities.syncExtract(workUri) }
                summaryLoading.value = false
            }
            try {
                val work: WorkEntity? = container.entities.refreshWork(workUri)
                if (work == null) {
                    if (cached == null) phase.value = WorkPhase.Error(null)
                    return@launch
                }
                phase.value = WorkPhase.Loaded(editionsSynced = false)
                container.entities.syncWorkEditions(workUri)
                phase.value = WorkPhase.Loaded(editionsSynced = true)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                // Whatever the store holds keeps showing; with nothing, the failure is the screen.
                phase.value = if (container.entities.entities.work(workUri) == null) {
                    WorkPhase.Error(error.localizedMessage)
                } else {
                    WorkPhase.Loaded(editionsSynced = true)
                }
            }
        }
    }

    /** Adding is optimistic; removing is server-first, so it answers whether it worked. */
    suspend fun toggleList(entry: MembershipEntry): Boolean = if (entry.isMember) {
        try {
            container.lists.removeEntities(entry.id, listOf(workUri))
            true
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            container.errorReporter.report(error)
            false
        }
    } else {
        container.lists.addEntities(entry.id, listOf(workUri))
        true
    }
}
