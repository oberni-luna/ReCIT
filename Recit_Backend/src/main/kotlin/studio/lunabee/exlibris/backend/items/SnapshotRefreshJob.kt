package studio.lunabee.exlibris.backend.items

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.sql.SQLException
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes

/**
 * The nightly snapshot refresh (decision 2), in the backend's own process: [SnapshotsService.refreshStale] a minute
 * after the start, then once a day. A round that fails is logged and the next one tries again.
 */
class SnapshotRefreshJob(
    private val snapshots: SnapshotsService,
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
        try {
            snapshots.refreshStale()
        } catch (error: ApiException) {
            logger.warn("Snapshot refresh stopped: {}", error.verbose)
        } catch (error: SQLException) {
            logger.error("Snapshot refresh stopped", error)
        }
    }

    private companion object {
        val FIRST_ROUND: Duration = 1.minutes
        val PERIOD: Duration = 24.hours

        val logger: Logger = LoggerFactory.getLogger(SnapshotRefreshJob::class.java)
    }
}
