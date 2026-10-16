package studio.lunabee.nouveaurecit.data.scan

/** `BatchScanState`: the one result row a scanning session shows, or none. */
sealed interface BatchScanState {
    data object Idle : BatchScanState

    data class LookingUp(val code: String) : BatchScanState

    /** inventaire.io knows no edition for the code — also where a timed-out lookup lands. */
    data class NotFound(val code: String) : BatchScanState

    data class Resolved(override val book: ScannedBook) : BatchScanState

    data class AlreadyOwned(override val book: ScannedBook) : BatchScanState

    data class Adding(override val book: ScannedBook) : BatchScanState

    data class Added(override val book: ScannedBook) : BatchScanState

    val book: ScannedBook? get() = null

    val showsRow: Boolean get() = this != Idle

    /** An offer or a write in flight: the row waits for the user, or for the server, not for a timer. */
    val holdsUntilActedOn: Boolean
        get() = this is Resolved || this is NotFound || this is Adding
}

/** `BatchScanEvent`. The camera fires [CodeSeen] for as long as a barcode is in frame. */
sealed interface BatchScanEvent {
    data class CodeSeen(val code: String) : BatchScanEvent

    data class LookupResolved(val book: ScannedBook) : BatchScanEvent

    /** The edition came back, and the user already has a copy of it — the check is the caller's. */
    data class LookupResolvedAlreadyOwned(val book: ScannedBook) : BatchScanEvent

    data class LookupFailed(val code: String) : BatchScanEvent

    /** The lookup ran past its deadline. The row says the same as [LookupFailed]. */
    data class LookupTimedOut(val code: String) : BatchScanEvent

    data object AddStarted : BatchScanEvent

    data object AddFinished : BatchScanEvent

    data object AddFailed : BatchScanEvent

    /** The row has said what it had to say and gives the screen back to the camera. */
    data object Cleared : BatchScanEvent
}
