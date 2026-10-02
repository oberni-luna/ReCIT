package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.flow.Flow
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.EditionWorkCrossRef
import studio.lunabee.nouveaurecit.data.db.EntityDao
import studio.lunabee.nouveaurecit.data.db.WorkAuthorCrossRef
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.data.db.WpExtractEntity
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.AuthorWorksDto
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.EntityResultsDto
import studio.lunabee.nouveaurecit.network.dto.ExtractDto
import studio.lunabee.nouveaurecit.network.dto.SummariesDto
import studio.lunabee.nouveaurecit.network.dto.WikidataProperty
import studio.lunabee.nouveaurecit.network.dto.WorkEditionsDto

/**
 * `EntityModel` and `ModelContext+Entities` (feature 0030): authors, works and editions enter the
 * store through one place, which looks the uri up, merges in place and unions the relationships —
 * so a work under two authors keeps both, and asking twice adds nothing.
 */
class EntityRepository(
    private val api: ApiService,
    private val dao: EntityDao,
) {
    fun observeEdition(uri: String): Flow<EditionEntity?> = dao.observeEdition(uri)

    fun observeWork(uri: String): Flow<WorkEntity?> = dao.observeWork(uri)

    fun observeAuthor(uri: String): Flow<AuthorEntity?> = dao.observeAuthor(uri)

    fun observeExtract(uri: String): Flow<WpExtractEntity?> = dao.observeExtract(uri)

    val entities: EntityDao get() = dao

    /** `/api/entities/by-uris`, 50 uris at a time. Keys may be canonical uris — iterate the values. */
    suspend fun fetchEntities(uris: List<String>, autocreate: Boolean = false): List<EntityResultDto> {
        if (uris.isEmpty()) return emptyList()
        return uris.distinct().chunked(50).flatMap { batch ->
            val query: MutableList<Pair<String, String>> = mutableListOf(
                "uris" to batch.joinToString("|"),
                "attributes" to "info|labels|descriptions|claims|image",
                "lang" to "fr",
            )
            if (autocreate) query += "autocreate" to "true"
            api.get<EntityResultsDto>("/api/entities/by-uris", *query.toTypedArray()).entities.values
        }
    }

    suspend fun upsertAuthors(dtos: List<EntityResultDto>): List<AuthorEntity> {
        val existing: Map<String, AuthorEntity> = dao.authors(dtos.map { it.uri }).associateBy { it.uri }
        val merged: List<AuthorEntity> = dtos.map { Merges.author(existing[it.uri], it) }
        dao.upsertAuthors(merged)
        return merged
    }

    suspend fun upsertWork(dto: EntityResultDto, authorUris: List<String>): WorkEntity {
        val merged: WorkEntity = Merges.work(dao.work(dto.uri), dto)
        dao.upsertWorks(listOf(merged))
        dao.linkWorkAuthors(authorUris.map { WorkAuthorCrossRef(dto.uri, it) })
        return merged
    }

    suspend fun upsertEdition(dto: EntityResultDto, workUris: List<String>): EditionEntity {
        val merged: EditionEntity = Merges.edition(dao.edition(dto.uri), dto)
        dao.upsertEditions(listOf(merged))
        linkEdition(dto.uri, workUris)
        return merged
    }

    suspend fun linkEdition(editionUri: String, workUris: List<String>) {
        dao.linkEditionWorks(workUris.map { EditionWorkCrossRef(editionUri, it) })
    }

    suspend fun getOrFetchAuthors(uris: List<String>): List<AuthorEntity> {
        val local: List<AuthorEntity> = dao.authors(uris)
        val missing: List<String> = uris - local.map { it.uri }.toSet()
        return local + upsertAuthors(fetchEntities(missing))
    }

    suspend fun getOrFetchWorks(uris: List<String>): List<WorkEntity> {
        val local: List<WorkEntity> = dao.works(uris)
        val missing: List<String> = uris - local.map { it.uri }.toSet()
        val fetched: List<WorkEntity> = fetchEntities(missing).map { dto -> upsertWorkWithAuthors(dto) }
        return local + fetched
    }

    suspend fun getOrFetchEditions(uris: List<String>): List<EditionEntity> {
        val local: List<EditionEntity> = dao.editions(uris)
        val missing: List<String> = uris - local.map { it.uri }.toSet()
        val fetched: List<EditionEntity> = fetchEntities(missing).map { dto ->
            upsertEdition(dto, resolveEditionWorks(dto))
        }
        return local + fetched
    }

    suspend fun refreshAuthor(uri: String): AuthorEntity? =
        fetchEntities(listOf(uri)).firstOrNull()?.let { upsertAuthors(listOf(it)).first() } ?: dao.author(uri)

    suspend fun refreshWork(uri: String): WorkEntity? =
        fetchEntities(listOf(uri)).firstOrNull()?.let { upsertWorkWithAuthors(it) } ?: dao.work(uri)

    suspend fun refreshEdition(uri: String, autocreate: Boolean = false): EditionEntity? =
        fetchEntities(listOf(uri), autocreate).firstOrNull()?.let { upsertEdition(it, resolveEditionWorks(it)) } ?: dao.edition(uri)

    /** `/api/entities/author-works`, then the works themselves, linked to the author. */
    suspend fun syncAuthorWorks(authorUri: String): List<WorkEntity> {
        val response: AuthorWorksDto = api.get("/api/entities/author-works", "uri" to authorUri, "refresh" to "false")
        val works: List<WorkEntity> = getOrFetchWorks(response.works.map { it.uri })
        dao.linkWorkAuthors(works.map { WorkAuthorCrossRef(it.uri, authorUri) })
        return works
    }

    /** `/api/entities/reverse-claims?property=wdt:P629` — the edition uris of a work, without fetching them. */
    suspend fun editionUris(workUri: String): List<String> {
        val response: WorkEditionsDto = api.get(
            "/api/entities/reverse-claims",
            "property" to WikidataProperty.EDITION_OF,
            "value" to workUri,
            "refresh" to "false",
        )
        return response.uris
    }

    suspend fun syncWorkEditions(workUri: String): List<EditionEntity> {
        val editions: List<EditionEntity> = getOrFetchEditions(editionUris(workUri))
        editions.forEach { linkEdition(it.uri, listOf(workUri)) }
        return editions
    }

    /** The Wikipedia extract: the French summary when inventaire.io has one, else the frwiki page. */
    suspend fun syncExtract(uri: String) {
        if (dao.extract(uri)?.content?.isNotEmpty() == true) return
        val summaries: SummariesDto = runCatching {
            api.get<SummariesDto>("/api/data/summaries", "uri" to uri, "langs" to "fr", "refresh" to "false")
        }.getOrNull() ?: return
        val summary = summaries.summaries.firstOrNull { it.key == WikidataProperty.SUMMARY && it.lang == "fr" }
        val extract: ExtractDto? = if (summary != null) {
            ExtractDto(summary.text.orEmpty(), summary.link.orEmpty())
        } else {
            val title: String = summaries.summaries.firstOrNull { it.key == "frwiki" }?.sitelink?.title ?: return
            runCatching { api.get<ExtractDto>("/api/data/wp-extract", "lang" to "fr", "title" to title) }.getOrNull()
        }
        if (extract != null) dao.upsertExtract(WpExtractEntity(uri, extract.extract, extract.url))
    }

    suspend fun setPreferredEdition(workUri: String, editionUri: String) = dao.setPreferredEdition(workUri, editionUri)

    private suspend fun upsertWorkWithAuthors(dto: EntityResultDto): WorkEntity {
        val authorUris: List<String> = dto.claimStrings(WikidataProperty.AUTHOR)
        runCatching { getOrFetchAuthors(authorUris) }
        val known: Set<String> = dao.authors(authorUris).map { it.uri }.toSet()
        return upsertWork(dto, authorUris.filter { it in known })
    }

    private suspend fun resolveEditionWorks(dto: EntityResultDto): List<String> {
        val workUris: List<String> = dto.claimStrings(WikidataProperty.EDITION_OF)
        if (workUris.isEmpty()) return emptyList()
        return runCatching { getOrFetchWorks(workUris).map { it.uri } }.getOrDefault(emptyList())
    }
}
