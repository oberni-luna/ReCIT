package studio.lunabee.exlibris.backend.items

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.lists.ElementUrisService
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.sql.SQLException
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes

/**
 * The nightly snapshot refresh (decision 2), in the backend's own process: [SnapshotsService.refreshStale] a minute
 * after the start, then once a day, and with it the lists' element URIs (#74, [ElementUrisService.refreshStale]).
 * A half that fails is logged, the other still runs, and the next round tries again.
 */
class SnapshotRefreshJob(
    private val snapshots: SnapshotsService,
    private val elementUris: ElementUrisService,
) {
    /** Runs until [scope] is cancelled: the application's, which stopping cancels. */
    fun start(scope: CoroutineScope): Job =
        scope.launch {
            delay(FIRST_ROUND)
            while (isActive) {
                round()
                delay(PERIOD)
            }
        }

    private suspend fun round() {
        attempt("Snapshot refresh") { snapshots.refreshStale() }
        attempt("Element URI check") { elementUris.refreshStale() }
    }

    private suspend fun attempt(
        name: String,
        work: suspend () -> Unit,
    ) {
        try {
            work()
        } catch (error: ApiException) {
            logger.warn("{} stopped: {}", name, error.verbose)
        } catch (error: SQLException) {
            logger.error("$name stopped", error)
        }
    }

    private companion object {
        val FIRST_ROUND: Duration = 1.minutes
        val PERIOD: Duration = 24.hours

        val logger: Logger = LoggerFactory.getLogger(SnapshotRefreshJob::class.java)
    }
}
