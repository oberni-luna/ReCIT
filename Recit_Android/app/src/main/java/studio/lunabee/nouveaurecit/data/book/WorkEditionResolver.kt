package studio.lunabee.nouveaurecit.data.book

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.InventoryDao
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto

/**
 * `AppModels/Entity/WorkEditionResolver.swift` plus `EntityModel.resolveBestEdition`: turns a work
 * into the one edition the app should open.
 *
 * Ranking writes nothing — it reads `reverse-claims` and the candidates' `by-uris` DTOs
 * ([EntityRepository.fetchEditionCandidates]) — and only the winner enters the store, through
 * [EntityRepository.refreshEdition], which upserts. The choice is then remembered on the work
 * (`preferredEditionUri`), so a second tap opens from the store and revalidates in the background.
 */
class WorkEditionResolver(
    private val entities: EntityRepository,
    private val inventoryDao: InventoryDao,
    private val backgroundScope: CoroutineScope,
) {
    /** The edition to open for [workUri], or `null` when the work has none with a name. */
    suspend fun resolveBestEdition(workUri: String): EditionEntity? {
        val preferred: String? = entities.entities.work(workUri)?.preferredEditionUri
        val cached: EditionEntity? = preferred?.let { entities.entities.edition(it) }
        if (cached != null) {
            revalidate(workUri)
            return cached
        }
        val uri: String = rankBestEditionUri(workUri) ?: return null
        val edition: EditionEntity? = entities.refreshEdition(uri)
        remember(workUri, uri)
        return edition
    }

    /** Runs the ladder and answers the winning uri, or `null` when the work has no edition. */
    suspend fun rankBestEditionUri(workUri: String, preferredLang: String = PREFERRED_LANG): String? {
        val uris: List<String> = entities.editionUris(workUri)
        if (uris.isEmpty()) return null
        val held: Set<String> = inventoryDao.heldEditionUris().toSet()
        val dtos: List<EntityResultDto> = EditionCandidates.ordered(uris, entities.fetchEditionCandidates(uris))
        val candidates: List<EditionRelevance.Candidate> = dtos.map { EditionCandidates.candidate(it, held) }
        val originalLang: String? = entities.entities.work(workUri)?.originalLang
        return EditionRelevance.best(candidates, preferredLang, originalLang)?.id
    }

    /**
     * The background half of a cached open: refresh the edition on screen, then replay the ladder in
     * case the corpus moved. Failures are swallowed — the reader is looking at a book either way.
     * One pass per work at a time.
     */
    private fun revalidate(workUri: String) {
        if (!revalidating.add(workUri)) return
        backgroundScope.launch {
            try {
                entities.entities.work(workUri)?.preferredEditionUri?.let { swallow { entities.refreshEdition(it) } }
                val uri: String? = swallow { rankBestEditionUri(workUri) }
                if (uri != null && uri != entities.entities.work(workUri)?.preferredEditionUri) {
                    swallow { entities.refreshEdition(uri) }
                    remember(workUri, uri)
                }
            } finally {
                revalidating.remove(workUri)
            }
        }
    }

    /** Looked up again rather than written through a reference held across round trips (issue 0067). */
    private suspend fun remember(workUri: String, editionUri: String) {
        val work = entities.entities.work(workUri) ?: return
        if (work.preferredEditionUri != editionUri) entities.setPreferredEdition(workUri, editionUri)
    }

    private suspend fun <T> swallow(block: suspend () -> T): T? = try {
        block()
    } catch (cancellation: CancellationException) {
        throw cancellation
    } catch (error: Exception) {
        null
    }

    companion object {
        /** The language the app reads in, hard-coded like the other `"fr"` (PRD 0014). */
        const val PREFERRED_LANG: String = "fr"

        /** The works being re-ranked right now, app-wide like `EntityModel.revalidatingWorkUris` (main thread only). */
        private val revalidating: MutableSet<String> = mutableSetOf()
    }
}
