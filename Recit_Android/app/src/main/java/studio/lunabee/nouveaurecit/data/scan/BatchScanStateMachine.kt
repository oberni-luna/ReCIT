package studio.lunabee.nouveaurecit.data.scan

/**
 * `BatchScanStateMachine` (feature 0007): which camera sightings count, and what the row says.
 * No camera, no Compose, no network — the clock is injected, so the gate is tested without sleeping.
 *
 * The repeat-scan gate is the feature. The camera reports a barcode continuously while it stays in
 * frame, so a book just added would be offered again forever. One result is pending at a time, and
 * the code just handled stays gated until a different one appears or it has been out of frame for
 * [cooldownMillis] — every sighting pushes that deadline back, refused ones included, so a wobbling
 * hand does not count as the book having been put down.
 *
 * The creation of a missing edition (`creationFinished` on iOS, feature 0020) is not ported.
 */
class BatchScanStateMachine(
    private val cooldownMillis: Long = DEFAULT_COOLDOWN_MILLIS,
    private val now: () -> Long = System::currentTimeMillis,
) {
    var state: BatchScanState = BatchScanState.Idle
        private set

    /** Books this session filed. Moves only on a confirmed add, and is never reset. */
    var addedBookCount: Int = 0
        private set

    private var gatedCode: String? = null
    private var gatedCodeLastSeen: Long = Long.MIN_VALUE

    /** Applies [event]; `false` when it does not fit the current state and changed nothing. */
    fun apply(event: BatchScanEvent): Boolean {
        val current: BatchScanState = state
        when (event) {
            is BatchScanEvent.CodeSeen -> return accept(event.code)

            is BatchScanEvent.LookupResolved -> {
                if (current !is BatchScanState.LookingUp || current.code != event.book.code) return false
                state = BatchScanState.Resolved(event.book)
            }

            is BatchScanEvent.LookupResolvedAlreadyOwned -> {
                if (current !is BatchScanState.LookingUp || current.code != event.book.code) return false
                state = BatchScanState.AlreadyOwned(event.book)
            }

            is BatchScanEvent.LookupFailed -> return fail(event.code)

            is BatchScanEvent.LookupTimedOut -> return fail(event.code)

            BatchScanEvent.AddStarted -> {
                if (current !is BatchScanState.Resolved) return false
                state = BatchScanState.Adding(current.book)
            }

            BatchScanEvent.AddFinished -> {
                if (current !is BatchScanState.Adding) return false
                state = BatchScanState.Added(current.book)
                addedBookCount += 1
            }

            // Back to the offer rather than off the screen: the user can tap again.
            BatchScanEvent.AddFailed -> {
                if (current !is BatchScanState.Adding) return false
                state = BatchScanState.Resolved(current.book)
            }

            BatchScanEvent.Cleared -> {
                if (current == BatchScanState.Idle) return false
                state = BatchScanState.Idle
            }
        }
        return true
    }

    // The row says so rather than stepping aside: saying nothing would look exactly like a scan the
    // camera never made. The code stays gated either way.
    private fun fail(code: String): Boolean {
        val current: BatchScanState = state
        if (current !is BatchScanState.LookingUp || current.code != code) return false
        state = BatchScanState.NotFound(code)
        return true
    }

    private fun accept(code: String): Boolean {
        val timestamp: Long = now()

        if (!isReplaceable(code)) {
            // Nothing may start while a result is pending — but a code still in frame keeps its place
            // in the gate, or it would be re-offered the instant the row clears.
            if (gatedCode == code) gatedCodeLastSeen = timestamp
            return false
        }

        if (gatedCode == code && timestamp - gatedCodeLastSeen < cooldownMillis) {
            gatedCodeLastSeen = timestamp
            return false
        }

        gatedCode = code
        gatedCodeLastSeen = timestamp
        state = BatchScanState.LookingUp(code)
        return true
    }

    /** An offer — a book to file, an unknown edition — gives way to a *different* barcode. */
    private fun isReplaceable(code: String): Boolean = when (val current: BatchScanState = state) {
        BatchScanState.Idle -> true
        is BatchScanState.NotFound -> current.code != code
        is BatchScanState.Resolved -> current.book.code != code
        is BatchScanState.LookingUp, is BatchScanState.AlreadyOwned, is BatchScanState.Adding, is BatchScanState.Added -> false
    }

    companion object {
        const val DEFAULT_COOLDOWN_MILLIS: Long = 2_000
    }
}
