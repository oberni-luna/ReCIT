package studio.lunabee.nouveaurecit.ui.scan

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.data.scan.BatchScanEvent
import studio.lunabee.nouveaurecit.data.scan.BatchScanState
import studio.lunabee.nouveaurecit.data.scan.BatchScanStateMachine
import studio.lunabee.nouveaurecit.data.scan.ScannedBook
import studio.lunabee.nouveaurecit.ui.createbook.CreateBookSession

/**
 * `BatchScanViewModel` (feature 0007): the camera's sightings, through [BatchScanStateMachine], into
 * a lookup, an ownership check and an add.
 *
 * - A barcode is an EAN-13 or nothing; the machine decides whether a sighting counts.
 * - The lookup is `isbn:<code>` with `autocreate`, under a ten-second deadline.
 * - Ownership is matched on the **canonical** uri of the edition that came back.
 * - The add waits on the server rather than being optimistic: in a batch the confirmation is the
 *   point, and an optimistic failure would surface twenty books later.
 * - An unknown edition can be created (feature 0020): [creation] is the form's session while it is up,
 *   and drafts are kept by ISBN for as long as the scanning session lasts.
 *
 * Scoped to the camera's entry in the flow, so a trip to a book's screen keeps the session.
 */
class ScanViewModel(private val container: AppContainer) : ViewModel() {
    private val machine: BatchScanStateMachine = BatchScanStateMachine()
    private val _state: MutableStateFlow<BatchScanState> = MutableStateFlow(machine.state)
    val state: StateFlow<BatchScanState> = _state.asStateFlow()

    private val _feedback: MutableSharedFlow<ScanFeedback> = MutableSharedFlow(extraBufferCapacity = 4)

    /** What the screen plays or says once: a haptic, or a failed add for the snackbar. */
    val feedback: SharedFlow<ScanFeedback> = _feedback.asSharedFlow()

    val addedBookCount: Int get() = machine.addedBookCount

    private val _creation: MutableStateFlow<CreateBookSession?> = MutableStateFlow(null)

    /** « Nouveau livre », while it is up. The camera is released under it and no barcode counts. */
    val creation: StateFlow<CreateBookSession?> = _creation.asStateFlow()

    /**
     * Drafts of books being created, by ISBN. The form is short-lived and the session is not: closing a
     * form that failed and coming back to the same barcode finds what was typed rather than asking twice.
     * Only a draft that became a book is forgotten — losing one is worse than keeping a few hundred bytes.
     */
    private val drafts: MutableMap<String, NewBookDraft> = mutableMapOf()

    private var lookupJob: Job? = null
    private var noticeJob: Job? = null
    private var confirmationJob: Job? = null

    fun codeSeen(code: String) {
        if (code.length != EAN_13_LENGTH || !code.all(Char::isDigit)) return
        if (_creation.value != null) return
        if (!apply(BatchScanEvent.CodeSeen(code))) return
        _feedback.tryEmit(ScanFeedback.Accepted)
        lookupJob?.cancel()
        lookupJob = viewModelScope.launch { lookUp(code) }
    }

    fun addPendingBook() {
        val pending: BatchScanState = machine.state
        if (pending !is BatchScanState.Resolved) return
        viewModelScope.launch {
            val me: UserEntity = container.users.myUser() ?: return@launch
            if (!apply(BatchScanEvent.AddStarted)) return@launch
            try {
                container.inventory.postNewItem(pending.book.uri, me, TransactionType.Inventorying, listOf(Visibility.Friends))
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                apply(BatchScanEvent.AddFailed)
                _feedback.tryEmit(ScanFeedback.AddFailed(error))
                return@launch
            }
            apply(BatchScanEvent.AddFinished)
            _feedback.tryEmit(ScanFeedback.Added)
            delay(CONFIRMATION_MILLIS)
            apply(BatchScanEvent.Cleared)
        }
    }

    /** The unknown row's button: « Nouveau livre », on the draft left from a previous attempt if any. */
    fun openCreation() {
        val pending: BatchScanState = machine.state
        if (pending !is BatchScanState.NotFound || _creation.value != null) return
        _creation.value = CreateBookSession(
            container = container,
            parentScope = viewModelScope,
            draft = drafts[pending.code] ?: NewBookDraft(isbn = pending.code),
            onCreated = ::bookCreated,
        )
    }

    /** Whatever takes the form away keeps what was typed. */
    fun closeCreation() {
        val session: CreateBookSession = _creation.value ?: return
        drafts[session.draft.isbn] = session.draft
        session.cancel()
        _creation.value = null
    }

    /**
     * The book now exists on inventaire.io and is in the inventory: the form did both writes. Same ending
     * as an add — the confirmed row, held as proof, then the camera — because to the user it is one act.
     */
    private fun bookCreated(book: ScannedBook) {
        drafts.remove(book.code)
        _creation.value?.cancel()
        _creation.value = null
        if (!apply(BatchScanEvent.CreationFinished(book))) return
        _feedback.tryEmit(ScanFeedback.Added)
        confirmationJob?.cancel()
        confirmationJob = viewModelScope.launch {
            delay(CONFIRMATION_MILLIS)
            apply(BatchScanEvent.Cleared)
        }
    }

    /** « Terminer »: nothing pending outlives the session. */
    fun cancelPending() {
        lookupJob?.cancel()
        noticeJob?.cancel()
        confirmationJob?.cancel()
        apply(BatchScanEvent.Cleared)
    }

    /** `OnboardingGate.presentsScanTally`: books were added, and there is no étagère to put them on. */
    suspend fun presentsTally(): Boolean {
        if (machine.addedBookCount == 0) return false
        val me: String = container.users.myUserId.value ?: return false
        return container.shelves.observeCountOf(me).first() == 0
    }

    private suspend fun lookUp(code: String) {
        val lookup: Lookup = try {
            withTimeoutOrNull(LOOKUP_TIMEOUT_MILLIS) { resolve(code)?.let(Lookup::Found) ?: Lookup.Missing } ?: Lookup.TimedOut
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (_: Exception) {
            Lookup.Missing
        }
        when (lookup) {
            Lookup.TimedOut -> showNotice(BatchScanEvent.LookupTimedOut(code), ScanFeedback.Failed)
            Lookup.Missing -> showNotice(BatchScanEvent.LookupFailed(code), ScanFeedback.Failed)
            is Lookup.Found -> if (isAlreadyOwned(lookup.book)) {
                showNotice(BatchScanEvent.LookupResolvedAlreadyOwned(lookup.book), ScanFeedback.Warning)
            } else {
                apply(BatchScanEvent.LookupResolved(lookup.book))
            }
        }
    }

    private suspend fun resolve(code: String): ScannedBook? {
        val edition: EditionEntity = container.entities.refreshEdition("isbn:$code", autocreate = true) ?: return null
        val workUris: List<String> = container.entities.entities.workUris(edition.uri)
        val authors: List<String> = if (workUris.isEmpty()) {
            emptyList()
        } else {
            container.entities.entities.observeAuthorsOfWorks(workUris).first().map { it.name }.distinct()
        }
        return ScannedBook(
            uri = edition.uri,
            title = edition.title,
            authors = authors.ifEmpty { edition.authorNames },
            coverImageUrl = edition.image,
            code = code,
        )
    }

    private suspend fun isAlreadyOwned(book: ScannedBook): Boolean {
        val me: String = container.users.myUserId.value ?: return false
        if (book.uri.isEmpty()) return false
        return container.database.inventoryDao().countOwned(book.uri, me) > 0
    }

    // A row that is not idle refuses every new barcode, so a notice that stayed up would strand the
    // scanner: what is not an offer clears itself after a beat.
    private fun showNotice(event: BatchScanEvent, feedback: ScanFeedback) {
        if (!apply(event)) return
        _feedback.tryEmit(feedback)
        noticeJob?.cancel()
        if (machine.state.holdsUntilActedOn) return
        noticeJob = viewModelScope.launch {
            delay(NOTICE_MILLIS)
            apply(BatchScanEvent.Cleared)
        }
    }

    private fun apply(event: BatchScanEvent): Boolean {
        val applied: Boolean = machine.apply(event)
        _state.value = machine.state
        return applied
    }

    private companion object {
        const val EAN_13_LENGTH: Int = 13
        const val LOOKUP_TIMEOUT_MILLIS: Long = 10_000
        const val NOTICE_MILLIS: Long = 3_000
        const val CONFIRMATION_MILLIS: Long = 900
    }

    private sealed interface Lookup {
        data class Found(val book: ScannedBook) : Lookup

        data object Missing : Lookup

        data object TimedOut : Lookup
    }
}

/** One-off feedback from a scanning session: what the phone plays, and what the snackbar says. */
sealed interface ScanFeedback {
    data object Accepted : ScanFeedback

    data object Added : ScanFeedback

    data object Warning : ScanFeedback

    data object Failed : ScanFeedback

    data class AddFailed(val error: Throwable) : ScanFeedback
}
