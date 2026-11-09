package studio.lunabee.nouveaurecit.data.user

import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration
import kotlin.time.TimeSource

/**
 * `RequestPacer` (iOS feature 0055): runs requests one after the other, a minimum interval apart.
 *
 * `PUT /api/user` is rate-limited per account with `minTimeBetweenRequests: 1000`: a second request less
 * than a second after the first is refused with a `429`, whatever it changes. A profile is saved one
 * attribute per request, so every `PUT /api/user` goes through the one pacer the container holds: they
 * queue, and each waits for its slot, [interval] after the start of the one before.
 */
class RequestPacer(
    private val interval: Duration,
    private val timeSource: TimeSource.WithComparableMarks = TimeSource.Monotonic,
) {
    private val queue: Mutex = Mutex()
    private var lastStart: ComparableTimeMark? = null

    suspend fun <T> run(operation: suspend () -> T): T = queue.withLock {
        lastStart?.let { start ->
            val elapsed: Duration = start.elapsedNow()
            if (elapsed < interval) delay(interval - elapsed)
        }
        lastStart = timeSource.markNow()
        operation()
    }
}
