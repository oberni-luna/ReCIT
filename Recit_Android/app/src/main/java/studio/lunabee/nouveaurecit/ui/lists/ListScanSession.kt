package studio.lunabee.nouveaurecit.ui.lists

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.data.scan.BatchScanEvent
import studio.lunabee.nouveaurecit.data.scan.BatchScanState
import studio.lunabee.nouveaurecit.data.scan.BatchScanStateMachine
import studio.lunabee.nouveaurecit.data.scan.ScannedBook

/**
 * `ListScanViewModel` (iOS feature 0060): the barcodes the list's scanner sees, turned into the one book
 * it offers to add, and that book into the works a list can hold.
 *
 * The gate is the batch scanner's own [BatchScanStateMachine] — which sightings count, which row a
 * different barcode may replace —, its lookup half only: the list's « + » files nothing into the
 * inventory, it hands the works to the list and the scanner closes. An edition with no work behind it
 * cannot go in a list, so it is told like an edition inventaire.io does not have.
 *
 * Lives as long as the scanner is on screen, in its [scope].
 */
internal class ListScanSession(private val container: AppContainer, private val scope: CoroutineScope) {
    private val machine: BatchScanStateMachine = BatchScanStateMachine()
    private val _state: MutableStateFlow<BatchScanState> = MutableStateFlow(machine.state)
    val state: StateFlow<BatchScanState> = _state.asStateFlow()

    /** The works of the book the row is offering, in the edition's order. */
    var works: List<ListWorkOption> = emptyList()
        private set

    private var lookupJob: Job? = null

    /** A barcode is in frame; most calls are refused by the gate. Returns whether this one counted. */
    fun codeSeen(code: String): Boolean {
        if (code.length != EAN_13_LENGTH || !code.all(Char::isDigit)) return false
        if (!apply(BatchScanEvent.CodeSeen(code))) return false
        works = emptyList()
        lookupJob?.cancel()
        lookupJob = scope.launch { lookUp(code) }
        return true
    }

    /** Gives the screen back to the camera — after « Continuer », when the book was already there. */
    fun clear() {
        lookupJob?.cancel()
        works = emptyList()
        apply(BatchScanEvent.Cleared)
    }

    private suspend fun lookUp(code: String) {
        val found: Pair<ScannedBook, List<ListWorkOption>>? = try {
            withTimeoutOrNull(LOOKUP_TIMEOUT_MILLIS) { resolve(code) }
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (_: Exception) {
            null
        }
        if (found == null) {
            apply(BatchScanEvent.LookupFailed(code))
            return
        }
        if (apply(BatchScanEvent.LookupResolved(found.first))) works = found.second
    }

    /** Asked with `autocreate`, as the batch scanner does: inventaire.io writes the editions its book-facts service knows. */
    private suspend fun resolve(code: String): Pair<ScannedBook, List<ListWorkOption>>? {
        val edition: EditionEntity = container.entities.refreshEdition("isbn:$code", autocreate = true) ?: return null
        val works: List<WorkEntity> = worksOf(container, edition.uri)
        if (works.isEmpty()) return null
        val authors: List<String> = container.entities.entities.observeAuthorsOfWorks(works.map { it.uri }).first().map { it.name }.distinct()
        val book = ScannedBook(
            uri = edition.uri,
            title = edition.title,
            authors = authors.ifEmpty { edition.authorNames },
            coverImageUrl = edition.image,
            code = code,
        )
        return book to works.map { ListWorkOption(it.uri, it.title) }
    }

    private fun apply(event: BatchScanEvent): Boolean {
        val applied: Boolean = machine.apply(event)
        _state.value = machine.state
        return applied
    }

    private companion object {
        const val EAN_13_LENGTH: Int = 13
        const val LOOKUP_TIMEOUT_MILLIS: Long = 10_000
    }
}
