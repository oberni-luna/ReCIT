package studio.lunabee.exlibris.backend.lists

import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.items.InventaireEntities
import studio.lunabee.exlibris.backend.items.InventaireEntitiesReader
import java.time.Clock
import java.time.Duration

/**
 * The elements' half of the nightly job (decision 4): a URI inventaire.io now redirects is replaced by its target, as
 * inventaire.io's merge moves its own elements. Each URI is checked once a week, [BATCH] to a request.
 */
class ElementUrisService(
    private val inventaire: InventaireEntitiesReader,
    private val repository: ElementUrisRepository,
    private val clock: Clock,
) {
    /**
     * Checks the URIs last checked more than [STALE_AFTER] ago; an entity inventaire.io no longer knows keeps its
     * URI. Answers how many were checked.
     */
    suspend fun refreshStale(): Int {
        val stale: List<String> = repository.checkedBefore(clock.millis() - STALE_AFTER.toMillis())
        stale.chunked(BATCH).forEach { uris ->
            val now: Long = clock.millis()
            val entities: InventaireEntities = inventaire.read(uris, mapOf("attributes" to listOf("info")))
            val (moved: List<String>, kept: List<String>) =
                uris.partition { entities.entity(it) != null && entities.canonical(it) != it }
            moved.forEach { repository.redirect(it, entities.canonical(it), now) }
            repository.markChecked(kept, now)
        }
        logger.info("Element URIs: {} checked", stale.size)
        return stale.size
    }

    private companion object {
        val STALE_AFTER: Duration = Duration.ofDays(7)
        const val BATCH: Int = 30

        val logger: Logger = LoggerFactory.getLogger(ElementUrisService::class.java)
    }
}
