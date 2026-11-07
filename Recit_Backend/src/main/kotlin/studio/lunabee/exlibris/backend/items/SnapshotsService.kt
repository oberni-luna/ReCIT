package studio.lunabee.exlibris.backend.items

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.entities.InventaireClient
import studio.lunabee.exlibris.backend.entities.RelayedResource
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.time.Clock
import java.time.Duration

/**
 * The books' snapshots (decision 2): read from inventaire.io's `/api/entities/by-uris`, anonymously, when a book is
 * created, stored per entity, and read again on a `bulk-update` and every night once a week old. inventaire.io
 * builds its own on every read; the backend reads inventaire.io as little as it can.
 */
class SnapshotsService(
    private val inventaire: InventaireClient,
    private val repository: SnapshotsRepository,
    private val clock: Clock,
) {
    /**
     * Reads [uri] on inventaire.io and stores its snapshot, under the URI inventaire.io answers it with — an `isbn:`
     * is stored under its edition's. An entity inventaire.io does not know, or that is neither an edition nor a work,
     * answers inventaire.io's `400`s; inventaire.io silent answers `502`, rather than a book without a title.
     */
    suspend fun store(uri: String): String {
        val outcome: SnapshotOutcome = SnapshotBuilder.build(uri, read(listOf(uri)), clock.millis())
        if (outcome !is SnapshotOutcome.Built) throw refusal(outcome)
        repository.save(outcome.snapshot)
        return outcome.snapshot.uri
    }

    suspend fun snapshots(uris: Collection<String>): Map<String, ItemSnapshot> = repository.find(uris)

    /**
     * Reads again those of [uris] read more than [REREAD_AFTER] ago: a `bulk-update` refreshes its books' snapshots,
     * at most once in that time, so that the Commentaire saved as it is typed does not ask inventaire.io each time.
     * inventaire.io unreachable leaves them as they are.
     */
    suspend fun refreshTouched(uris: Collection<String>) {
        val due: List<String> = repository.readBefore(clock.millis() - REREAD_AFTER.toMillis(), uris)
        if (due.isEmpty()) return
        try {
            refresh(due)
        } catch (error: ApiException) {
            logger.warn("Snapshots of {} kept: {}", due, error.verbose)
        }
    }

    /**
     * The nightly job: drops the snapshots no book uses, then reads again those read more than [STALE_AFTER] ago,
     * [BATCH] to a request. Answers how many were read.
     */
    suspend fun refreshStale(): Int {
        val dropped: Int = repository.deleteUnused()
        val stale: List<String> = repository.readBefore(clock.millis() - STALE_AFTER.toMillis())
        stale.chunked(BATCH).forEach { refresh(it) }
        logger.info("Snapshots: {} dropped, {} read again", dropped, stale.size)
        return stale.size
    }

    /**
     * Reads [uris] again. A redirect moves their books to the URI inventaire.io answers, as its merge does; an entity
     * it no longer knows keeps its last snapshot.
     */
    private suspend fun refresh(uris: List<String>) {
        val now: Long = clock.millis()
        val entities: InventaireEntities = read(uris)
        uris.forEach { uri ->
            when (val outcome: SnapshotOutcome = SnapshotBuilder.build(uri, entities, now)) {
                is SnapshotOutcome.Built -> {
                    repository.save(outcome.snapshot)
                    if (outcome.snapshot.uri != uri) repository.moveItems(uri, outcome.snapshot.uri)
                }

                SnapshotOutcome.NotFound, SnapshotOutcome.InvalidType, SnapshotOutcome.NoTitle -> {
                    logger.warn("Snapshot of {} kept: inventaire.io answered {}", uri, outcome)
                    repository.markRead(listOf(uri), now)
                }
            }
        }
    }

    private fun refusal(outcome: SnapshotOutcome): ApiException =
        ApiException(
            HttpStatusCode.BadRequest,
            when (outcome) {
                SnapshotOutcome.InvalidType -> "invalid entity type"
                SnapshotOutcome.NoTitle -> "no title found"
                SnapshotOutcome.NotFound, is SnapshotOutcome.Built -> "some entities could not be found"
            },
        )

    private suspend fun read(uris: List<String>): InventaireEntities {
        // `|` encoded: inventaire.io takes either, a stricter server only this.
        val path: String =
            "/api/entities/by-uris?uris=${uris.joinToString(SEPARATOR)}" +
                "&relatives=${SnapshotBuilder.relatives.joinToString(SEPARATOR)}"
        return inventaire.get(path, emptyMap(), RelayedResource.DATA.timeout) { response -> parse(response) }
    }

    private suspend fun parse(response: HttpResponse): InventaireEntities {
        if (response.status != HttpStatusCode.OK) {
            logger.warn("inventaire.io answered {} to by-uris", response.status.value)
            throw ApiException.badGateway()
        }
        // kotlinx's `SerializationException` and a body of the wrong shape are both `IllegalArgumentException`s.
        return try {
            InventaireEntities.parse(response.bodyAsText())
        } catch (error: IllegalArgumentException) {
            throw ApiException.badGateway(error)
        }
    }

    private companion object {
        val REREAD_AFTER: Duration = Duration.ofMinutes(10)
        val STALE_AFTER: Duration = Duration.ofDays(7)
        const val BATCH: Int = 30
        const val SEPARATOR: String = "%7C"

        val logger: Logger = LoggerFactory.getLogger(SnapshotsService::class.java)
    }
}
