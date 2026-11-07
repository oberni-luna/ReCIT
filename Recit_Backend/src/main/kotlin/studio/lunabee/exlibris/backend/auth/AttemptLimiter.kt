package studio.lunabee.exlibris.backend.auth

import java.time.Clock
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap

/**
 * At most [limit] attempts per key within a sliding [window], in memory: one instance of the backend (#62).
 * Keys are what an IP-based Ktor `RateLimit` cannot see, an identifier or an address read from the body.
 */
class AttemptLimiter(
    private val limit: Int,
    private val window: Duration,
    private val clock: Clock,
) {
    private val attempts: ConcurrentHashMap<String, List<Long>> = ConcurrentHashMap()

    /** Counts an attempt for [key], unless [limit] attempts already fall within the window. */
    fun tryAcquire(key: String): Boolean {
        val now: Long = clock.millis()
        var isAllowed = false
        attempts.compute(key) { _, previous ->
            val recent: List<Long> = previous.orEmpty().filter { now - it < window.toMillis() }
            isAllowed = recent.size < limit
            if (isAllowed) recent + now else recent
        }
        if (attempts.size > SWEEP_THRESHOLD) {
            attempts.entries.removeIf { (_, times) -> times.all { now - it >= window.toMillis() } }
        }
        return isAllowed
    }

    private companion object {
        const val SWEEP_THRESHOLD: Int = 10_000
    }
}
